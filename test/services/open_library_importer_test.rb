# frozen_string_literal: true

require "test_helper"

class OpenLibraryImporterTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:code, :body)

  class FakeTransport
    attr_reader :requests

    def initialize(&handler)
      @handler = handler
      @requests = []
    end

    def get(uri, **options)
      @requests << [ uri, options ]
      @handler.call(uri, options)
    end
  end

  test "normalizes, deduplicates, batches, and enriches Open Library data" do
    transport = FakeTransport.new do |uri, _options|
      case uri.path
      when "/search.json"
        FakeResponse.new("200", { docs: search_documents }.to_json)
      when "/authors/OL1A.json"
        FakeResponse.new("200", { birth_date: "2 January 1970", bio: { value: "Author biography" } }.to_json)
      when "/authors/OL2A.json"
        FakeResponse.new("200", { birth_date: "1980", bio: "Second biography" }.to_json)
      else
        FakeResponse.new("404", {}.to_json)
      end
    end

    result = importer(transport).call(author_limit: 2, book_limit: 3)

    assert_equal [ "/authors/OL1A", "/authors/OL2A" ], result.authors.pluck(:open_library_key)
    assert_equal Date.new(1970, 1, 2), result.authors.first[:date_of_birth]
    assert_equal "Author biography", result.authors.first[:short_description]
    assert_equal 3, result.books.length
    assert_equal 3, result.books.pluck(:open_library_key).uniq.length
    assert_equal "Opening sentence.", result.books.first[:summary]
    assert_empty result.warnings

    detail_paths = transport.requests.map { |request| request.first.path }.grep(%r{\A/authors/})
    assert_equal [ "/authors/OL1A.json", "/authors/OL2A.json" ], detail_paths.sort
    assert transport.requests.all? { |_uri, options| options[:headers]["User-Agent"].include?("tests@example.test") }
  end

  test "retries a transient response and returns partial result warnings without live network" do
    attempts = 0
    transport = FakeTransport.new do |uri, _options|
      if uri.path == "/search.json"
        attempts += 1
        next FakeResponse.new("503", "") if attempts == 1

        FakeResponse.new("200", { docs: search_documents.first(1) }.to_json)
      else
        FakeResponse.new("500", "")
      end
    end

    result = importer(transport, max_retries: 1).call(author_limit: 1, book_limit: 1)

    assert_equal 1, result.books.length
    assert_equal 1, result.authors.length
    assert result.warnings.any? { |warning| warning.include?("Author detail") }
    assert_operator attempts, :>=, 2
  end

  test "malformed and failed searches produce an empty import for fallback" do
    transport = FakeTransport.new { |_uri, _options| FakeResponse.new("200", "not-json") }

    result = importer(transport).call(author_limit: 2, book_limit: 3)

    assert_empty result.authors
    assert_empty result.books
    assert result.warnings.any? { |warning| warning.include?("malformed JSON") }
  end

  test "retries and translates TLS and HTTP protocol transport failures for fallback" do
    [ OpenSSL::SSL::SSLError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError ].each do |error_class|
      attempts = 0
      transport = FakeTransport.new do |_uri, _options|
        attempts += 1
        raise error_class, "simulated transport failure"
      end

      result = importer(transport, max_retries: 1).call(author_limit: 1, book_limit: 1)

      assert_empty result.authors, error_class.name
      assert_empty result.books, error_class.name
      assert_equal 2, attempts, error_class.name
      assert result.warnings.any? { |warning| warning.include?(error_class.name) }, error_class.name
    end
  end

  test "retains a useful work when publication metadata is missing" do
    document = {
      "key" => "/works/OL99W",
      "title" => "Undated Work",
      "author_key" => [ "OL9A" ],
      "author_name" => [ "Known Author" ]
    }
    transport = FakeTransport.new do |uri, _options|
      body = uri.path == "/search.json" ? { docs: [ document ] } : {}
      FakeResponse.new("200", body.to_json)
    end

    result = importer(transport).call(author_limit: 1, book_limit: 1)

    assert_equal 1, result.authors.length
    assert_equal 1, result.books.length
    assert_nil result.books.first[:date_of_publication]
    assert_nil result.books.first[:summary]
  end

  test "interleaves discovery subjects instead of filling authors from the first result set" do
    fiction = discovery_document(author_number: 1, work_number: 1, title: "Fiction Work")
    fiction_second = discovery_document(author_number: 2, work_number: 2, title: "Second Fiction Work")
    history = discovery_document(author_number: 3, work_number: 3, title: "History Work")
    transport = FakeTransport.new do |uri, _options|
      query = URI.decode_www_form(uri.query.to_s).to_h.fetch("q", "")
      docs = if query == "subject:fiction"
        [ fiction, fiction_second ]
      elsif query == "subject:history"
        [ history ]
      else
        []
      end
      FakeResponse.new("200", { docs: docs }.to_json)
    end
    importer = OpenLibraryImporter.new(
      transport: transport,
      base_url: "https://openlibrary.test",
      user_agent: "test-agent",
      request_interval: 0,
      max_retries: 0,
      sleeper: ->(_seconds) { },
      logger: nil,
      discovery_queries: [ "subject:fiction", "subject:history" ]
    )

    result = importer.call(author_limit: 2, book_limit: 2)

    assert_equal [ "/authors/OL1A", "/authors/OL3A" ], result.authors.pluck(:open_library_key)
    assert_equal [ "Fiction Work", "History Work" ], result.books.pluck(:name)
  end

  test "continues past duplicate raw pages until the usable work target is met" do
    first = discovery_document(author_number: 1, work_number: 1, title: "First Work")
    second = discovery_document(author_number: 1, work_number: 2, title: "Second Work")
    transport = FakeTransport.new do |uri, _options|
      params = URI.decode_www_form(uri.query.to_s).to_h
      docs = if params.fetch("q", "").start_with?("author_key:")
        params.fetch("page", "1") == "1" ? Array.new(100, first) : [ second ]
      else
        [ first ]
      end
      FakeResponse.new("200", { docs: docs }.to_json)
    end

    result = importer(transport).call(author_limit: 1, book_limit: 2)

    assert_equal [ "/works/OL1W", "/works/OL2W" ], result.books.pluck(:open_library_key)
    requested_pages = transport.requests.filter_map do |uri, _options|
      params = URI.decode_www_form(uri.query.to_s).to_h
      params["page"] if params.fetch("q", "").start_with?("author_key:")
    end
    assert_equal [ "1", "2" ], requested_pages
  end

  test "caps full unusable work-search pages per author batch" do
    discovery = discovery_document(author_number: 1, work_number: 1, title: "Discovery Work")
    unusable = discovery.merge("key" => nil, "title" => nil)
    transport = FakeTransport.new do |uri, _options|
      query = URI.decode_www_form(uri.query.to_s).to_h.fetch("q", "")
      docs = query.start_with?("author_key:") ? Array.new(100, unusable) : [ discovery ]
      FakeResponse.new("200", { docs: docs }.to_json)
    end

    result = importer(transport).call(author_limit: 1, book_limit: 2)

    work_searches = transport.requests.count do |uri, _options|
      URI.decode_www_form(uri.query.to_s).to_h.fetch("q", "").start_with?("author_key:")
    end
    assert_equal OpenLibraryImporter::MAX_WORK_SEARCH_PAGES_PER_BATCH, work_searches
    assert_equal [ "/works/OL1W" ], result.books.pluck(:open_library_key)
    assert_operator result.skipped_records, :positive?
  end

  private

  def importer(transport, max_retries: 0)
    OpenLibraryImporter.new(
      transport: transport,
      base_url: "https://openlibrary.test",
      contact_email: "tests@example.test",
      max_retries: max_retries,
      request_interval: 0,
      sleeper: ->(_seconds) { },
      logger: nil,
      discovery_queries: [ "subject:test" ]
    )
  end

  def search_documents
    [
      {
        "key" => "/works/OL11W",
        "title" => "First Book",
        "author_key" => [ "OL1A" ],
        "author_name" => [ "First Author" ],
        "first_publish_year" => 2001,
        "first_sentence" => [ "Opening sentence." ]
      },
      {
        "key" => "OL12W",
        "title" => "Second Book",
        "author_key" => [ "/authors/OL1A" ],
        "author_name" => [ "First Author" ],
        "first_publish_year" => 2002
      },
      {
        "key" => "/works/OL21W",
        "title" => "Third Book",
        "author_key" => [ "OL2A" ],
        "author_name" => [ "Second Author" ],
        "first_publish_year" => 2003
      },
      {
        "key" => "/works/OL11W",
        "title" => "Duplicate First Book",
        "author_key" => [ "OL1A" ],
        "author_name" => [ "First Author" ],
        "first_publish_year" => 2001
      }
    ]
  end

  def discovery_document(author_number:, work_number:, title:)
    {
      "key" => "/works/OL#{work_number}W",
      "title" => title,
      "author_key" => [ "OL#{author_number}A" ],
      "author_name" => [ "Author #{author_number}" ],
      "first_publish_year" => 2000 + work_number
    }
  end
end
