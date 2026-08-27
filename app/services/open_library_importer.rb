# frozen_string_literal: true

require "date"
require "json"
require "net/http"
require "openssl"
require "uri"

# Fetches and normalizes bibliographic records from Open Library. Persistence,
# synthetic fallback data, and assignment-specific review/sale generation live
# in AssignmentDatasetBuilder so this integration remains independently testable.
class OpenLibraryImporter
  class Error < StandardError; end
  class RequestError < Error; end
  class InvalidResponseError < Error; end

  Result = Struct.new(:authors, :books, :warnings, :skipped_records, keyword_init: true) do
    def self.empty(warnings: [])
      new(authors: [], books: [], warnings: warnings, skipped_records: 0)
    end
  end

  DEFAULT_BASE_URL = "https://openlibrary.org"
  DEFAULT_DISCOVERY_QUERIES = [
    "subject:fiction language:eng",
    "subject:history language:eng",
    "subject:science language:eng",
    "subject:biography language:eng"
  ].freeze
  SEARCH_FIELDS = %w[
    key title author_key author_name first_publish_year first_sentence subject
  ].join(",").freeze
  SEARCH_PAGE_SIZE = 100
  AUTHOR_QUERY_BATCH_SIZE = 10
  MAX_WORK_SEARCH_PAGES_PER_BATCH = 5
  RETRYABLE_STATUS_CODES = [ 429, 500, 502, 503, 504 ].freeze
  RETRYABLE_ERRORS = [
    Timeout::Error,
    SocketError,
    EOFError,
    IOError,
    SystemCallError,
    OpenSSL::SSL::SSLError,
    Net::HTTPBadResponse,
    Net::HTTPHeaderSyntaxError,
    Net::ProtocolError
  ].freeze

  class NetHttpTransport
    def get(uri, headers:, open_timeout:, read_timeout:)
      request = Net::HTTP::Get.new(uri)
      headers.each { |name, value| request[name] = value }

      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: open_timeout,
        read_timeout: read_timeout
      ) { |http| http.request(request) }
    end
  end

  def initialize(
    transport: NetHttpTransport.new,
    base_url: ENV.fetch("OPEN_LIBRARY_BASE_URL", DEFAULT_BASE_URL),
    contact_email: ENV["OPEN_LIBRARY_CONTACT_EMAIL"],
    user_agent: ENV["OPEN_LIBRARY_USER_AGENT"],
    open_timeout: ENV.fetch("OPEN_LIBRARY_OPEN_TIMEOUT", 5).to_f,
    read_timeout: ENV.fetch("OPEN_LIBRARY_READ_TIMEOUT", 10).to_f,
    max_retries: ENV.fetch("OPEN_LIBRARY_RETRIES", 2).to_i,
    request_interval: ENV["OPEN_LIBRARY_REQUEST_INTERVAL"],
    sleeper: ->(seconds) { sleep(seconds) },
    clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) },
    logger: defined?(Rails) ? Rails.logger : nil,
    discovery_queries: DEFAULT_DISCOVERY_QUERIES
  )
    @transport = transport
    @base_url = base_url.to_s.delete_suffix("/")
    @open_timeout = [ open_timeout, 0.1 ].max
    @read_timeout = [ read_timeout, 0.1 ].max
    @max_retries = [ [ max_retries, 0 ].max, 4 ].min
    @sleeper = sleeper
    @clock = clock
    @request_interval = normalized_request_interval(request_interval, contact_email, user_agent)
    @last_request_at = nil
    @logger = logger
    @discovery_queries = Array(discovery_queries).map(&:to_s).reject(&:empty?)
    @user_agent = user_agent.presence || default_user_agent(contact_email)
    @author_detail_cache = {}
  end

  # Returns normalized hashes and never makes persistence changes. Search and
  # individual author failures are recorded as warnings, allowing the builder
  # to supplement only the resulting deficits with local fallback data.
  def call(author_limit: 50, book_limit: 300)
    author_limit = positive_integer(author_limit, "author_limit")
    book_limit = positive_integer(book_limit, "book_limit")
    warnings = []

    discovery_documents = discover_documents(author_limit, warnings)
    selected_authors = select_authors(discovery_documents, author_limit)

    if selected_authors.empty?
      return Result.empty(warnings: warnings << "Open Library returned no usable author records")
    end

    expanded_documents = fetch_books_for_authors(selected_authors, discovery_documents, book_limit, warnings)
    candidate_documents = discovery_documents + expanded_documents
    books = normalize_books(candidate_documents, selected_authors, book_limit)
    # Keep every valid discovered author, including authors whose returned works
    # were incomplete, so the preferred real source is used wherever supported.
    # Synthetic fallback books are deliberately assigned to synthetic authors by
    # AssignmentDatasetBuilder rather than asserting unsupported real authorship.
    authors = selected_authors.values.map { |author| enrich_author(author, warnings) }

    Result.new(
      authors: authors,
      books: books,
      warnings: warnings,
      skipped_records: count_incomplete_documents(candidate_documents, selected_authors)
    )
  rescue ArgumentError
    raise
  rescue Error => error
    warn_once(warnings, "Open Library import stopped: #{error.message}")
    Result.empty(warnings: warnings)
  end

  private

  def discover_documents(author_limit, warnings)
    query_results = @discovery_queries.filter_map do |query|
      begin
        search(query: query, limit: SEARCH_PAGE_SIZE)
      rescue Error => error
        warn_once(warnings, "Discovery query #{query.inspect} failed: #{error.message}")
        nil
      end
    end

    documents = []
    seen_author_keys = {}
    maximum_result_length = query_results.map(&:length).max.to_i

    maximum_result_length.times do |index|
      query_results.each do |results|
        document = results[index]
        next unless document

        documents << document
        author_key = primary_author(document)&.fetch(:key, nil)
        seen_author_keys[author_key] = true if author_key
        return documents if seen_author_keys.length >= author_limit
      end
    end

    documents
  end

  def select_authors(documents, author_limit)
    documents.each_with_object({}) do |document, authors|
      break authors if authors.length >= author_limit

      author = primary_author(document)
      authors[author[:key]] ||= author if author
    end
  end

  def fetch_books_for_authors(selected_authors, initial_documents, book_limit, warnings)
    return [] if normalize_books(initial_documents, selected_authors, book_limit).length >= book_limit

    documents = []

    selected_authors.keys.each_slice(AUTHOR_QUERY_BATCH_SIZE) do |keys|
      query = keys.map { |key| "author_key:#{key.delete_prefix('/authors/')}" }.join(" OR ")
      page = 1

      while page <= MAX_WORK_SEARCH_PAGES_PER_BATCH
        begin
          batch = search(query: query, limit: SEARCH_PAGE_SIZE, page: page)
          documents.concat(batch)
          usable_count = normalize_books(initial_documents + documents, selected_authors, book_limit).length
          return documents if usable_count >= book_limit
          break if batch.length < SEARCH_PAGE_SIZE
          page += 1
        rescue Error => error
          warn_once(warnings, "Work search for an author batch failed: #{error.message}")
          break
        end
      end
    end

    documents
  end

  def search(query:, limit:, page: 1)
    payload = get_json(
      "/search.json",
      q: query,
      fields: SEARCH_FIELDS,
      limit: [ [ limit.to_i, 1 ].max, SEARCH_PAGE_SIZE ].min,
      page: page
    )
    documents = payload["docs"]
    raise InvalidResponseError, "search response did not contain a docs array" unless documents.is_a?(Array)

    documents.select { |document| document.is_a?(Hash) }
  end

  def normalize_books(documents, selected_authors, book_limit)
    books_by_key = {}

    documents.each do |document|
      author = primary_author(document)
      next unless author && selected_authors.key?(author[:key])

      key = canonical_key(document["key"], "works", "W")
      title = clean_text(document["title"])
      year = normalized_year(document["first_publish_year"])
      next unless key && title

      books_by_key[key] ||= {
        open_library_key: key,
        author_key: author[:key],
        name: title,
        summary: extract_text(document["first_sentence"]),
        date_of_publication: year ? Date.new(year, 1, 1) : nil
      }
      break if books_by_key.length >= book_limit
    end

    books_by_key.values
  end

  def count_incomplete_documents(documents, selected_authors)
    documents.count do |document|
      author = primary_author(document)
      author.nil? || (
        selected_authors.key?(author[:key]) &&
        (canonical_key(document["key"], "works", "W").nil? || clean_text(document["title"]).nil?)
      )
    end
  end

  def primary_author(document)
    keys = Array(document["author_key"])
    names = Array(document["author_name"])
    key = canonical_key(keys.first, "authors", "A")
    name = clean_text(names.first)
    return unless key && name

    { open_library_key: key, key: key, name: name }
  end

  def enrich_author(author, warnings)
    detail = author_detail(author.fetch(:key))

    {
      open_library_key: author.fetch(:key),
      name: author.fetch(:name),
      date_of_birth: parse_date(detail["birth_date"]),
      country_of_origin: nil,
      short_description: extract_text(detail["bio"] || detail["description"])
    }
  rescue Error => error
    warn_once(warnings, "Author detail #{author.fetch(:key)} failed: #{error.message}")
    {
      open_library_key: author.fetch(:key),
      name: author.fetch(:name),
      date_of_birth: nil,
      country_of_origin: nil,
      short_description: nil
    }
  end

  def author_detail(key)
    @author_detail_cache[key] ||= get_json("#{key}.json")
  end

  def get_json(path, query = {})
    uri = build_uri(path, query)
    attempts = 0

    loop do
      attempts += 1
      begin
        throttle_request!
        response = @transport.get(
          uri,
          headers: { "Accept" => "application/json", "User-Agent" => @user_agent },
          open_timeout: @open_timeout,
          read_timeout: @read_timeout
        )
      rescue *RETRYABLE_ERRORS => error
        raise RequestError, "#{error.class}: #{error.message}" if attempts > @max_retries

        retry_after(attempts)
        next
      end

      status = response.code.to_i

      if status == 200
        begin
          parsed = JSON.parse(response.body.to_s)
        rescue JSON::ParserError => error
          raise InvalidResponseError, "malformed JSON for #{uri}: #{error.message}"
        end
        raise InvalidResponseError, "JSON root was not an object" unless parsed.is_a?(Hash)

        return parsed
      end

      retryable = RETRYABLE_STATUS_CODES.include?(status)
      raise RequestError, "HTTP #{status} for #{uri}" unless retryable && attempts <= @max_retries

      retry_after(attempts)
    end
  end

  def build_uri(path, query)
    uri = URI.parse("#{@base_url}#{path}")
    unless %w[http https].include?(uri.scheme) && uri.host
      raise ArgumentError, "OPEN_LIBRARY_BASE_URL must be an HTTP(S) URL"
    end

    uri.query = URI.encode_www_form(query) if query.any?
    uri
  end

  def retry_after(attempt)
    @sleeper.call([ 0.25 * (2**(attempt - 1)), 2.0 ].min)
  end

  def throttle_request!
    now = @clock.call
    if @last_request_at
      remaining = @request_interval - (now - @last_request_at)
      @sleeper.call(remaining) if remaining.positive?
      now = @clock.call
    end
    @last_request_at = now
  end

  def normalized_request_interval(value, contact_email, user_agent)
    default = contact_email.to_s.strip.empty? && user_agent.to_s.strip.empty? ? 1.0 : (1.0 / 3.0)
    interval = value.nil? ? default : Float(value)
    [ interval, 0.0 ].max
  rescue ArgumentError, TypeError
    default
  end

  def parse_date(value)
    text = clean_text(value)
    return unless text

    return Date.new(text.to_i, 1, 1) if text.match?(/\A\d{4}\z/)

    Date.parse(text)
  rescue Date::Error
    nil
  end

  def normalized_year(value)
    year = Integer(value, exception: false)
    year if year&.between?(1, 9999)
  end

  def extract_text(value)
    value = value["value"] || value[:value] if value.is_a?(Hash)
    value = value.first if value.is_a?(Array)
    clean_text(value)
  end

  def clean_text(value)
    value.to_s.squish.presence
  end

  def canonical_key(value, collection, suffix)
    raw = value.to_s.strip
    identifier = raw[%r{(?:/)?#{Regexp.escape(collection)}/(OL\d+#{suffix})\z}i, 1] ||
      raw[/\A(OL\d+#{suffix})\z/i, 1]
    "/#{collection}/#{identifier.upcase}" if identifier
  end

  def positive_integer(value, name)
    integer = Integer(value)
    raise ArgumentError, "#{name} must be positive" unless integer.positive?

    integer
  end

  def default_user_agent(contact_email)
    contact = contact_email.to_s.strip
    suffix = contact.empty? ? "academic seed importer" : contact
    "SoftwareArchitectureAssignment/1.0 (#{suffix})"
  end

  def warn_once(warnings, message)
    warnings << message unless warnings.include?(message)
    @logger&.warn(message)
  end
end
