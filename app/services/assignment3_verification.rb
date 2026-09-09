# Executable development checks, deliberately not an assignment report.
class Assignment3Verification
  def initialize(output: $stdout)
    @output = output
    @created = []
    @token = "verify#{SecureRandom.hex(8)}"
  end

  def call
    @output.sync = true if @output.respond_to?(:sync=)
    raise "Run only in development or test" unless Rails.env.development? || Rails.env.test?
    raise "Enable both CACHE_ENABLED and SEARCH_ENABLED" unless ReadCache.enabled? && Search::Connection.enabled?

    check("Redis connectivity") { ReadCache.store.redis.with { |redis| redis.ping == "PONG" } }
    check("OpenSearch connectivity") { %w[green yellow].include?(Search::Connection.client.cluster.health["status"]) }
    Search::Indexer.new.ensure_index!
    @session = ActionDispatch::Integration::Session.new(Rails.application)
    @session.host! "localhost"

    author = create(Author, name: "Verification #{@token}")
    book = create(Book, author_id: author.id, name: "title#{@token}", summary: "summary#{@token}", date_of_publication: "2000-01-01")
    other = create(Book, author_id: author.id, name: "Other #{@token}", summary: "paged#{@token}", date_of_publication: "2000-01-01")
    review = create(Review, book_id: book.id, review_text: "oldreview#{@token} paged#{@token}", score: 5)
    # Ensure this book competes inside the top ten even in the seeded dataset.
    10.times { create(Review, book_id: book.id, review_text: "paged#{@token}", score: 5) }
    projections(book, author, "initial")
    key = CacheKeys.average(book.id)
    check("average was populated in real Redis") do
      ReadCache.store.exist?(CacheKeys.versioned(key, CacheRevision.versions([ key ]).fetch(key)))
    end
    @output.puts "Initial average=#{book.average_score}; author sales=#{author_row(author).total_sales}"
    %w[title summary oldreview].each { |field| search_is("#{field}#{@token}", [ book.id ], "matches #{field}") }

    first = search("paged#{@token}", page: 1, per_page: 1)
    second = search("paged#{@token}", page: 2, per_page: 1)
    check("unique-book count and pagination despite many matching reviews") do
      first.total_count == 2 && first.total_pages == 2 && second.current_page == 2 &&
        (first.records + second.records).map(&:id).sort == [ book.id, other.id ].sort
    end
    raw = Search::Connection.client.search(index: Search::Connection.index, body: {
      query: { multi_match: { query: "paged#{@token}", fields: [ "title^2", "summary", "review_text" ], operator: "or" } },
      collapse: { field: "book_id" }, sort: [ { _score: "desc" }, { book_id: "asc" } ]
    })
    expected_order = raw.fetch("hits").fetch("hits").map { |hit| hit.fetch("_source").fetch("book_id").to_i }
    check("PostgreSQL hydration preserves OpenSearch relevance order") { search("paged#{@token}").records.map(&:id) == expected_order }

    update(review, score: 1, review_text: "newreview#{@token} paged#{@token}")
    check("review edit changes average") { book.average_score < 5 }
    projections(book, author, "review update")
    search_is("oldreview#{@token}", [], "old review text removed")
    search_is("newreview#{@token}", [ book.id ], "changed review text indexed")
    added = create(Review, book_id: book.id, score: 2, review_text: "added#{@token}")
    projections(book, author, "review create")
    search_is("added#{@token}", [ book.id ], "new review indexed")
    destroy(added)
    projections(book, author, "review delete")
    search_is("added#{@token}", [], "deleted review removed")

    sale = create(Sale, book_id: book.id, year: 2000, sales: 9_000_000)
    projections(book, author, "sale create")
    update(sale, sales: 9_000_030)
    projections(book, author, "sale update")
    added_sale = create(Sale, book_id: book.id, year: 2001, sales: 70)
    projections(book, author, "second sale create")
    destroy(added_sale)
    destroy(sale)
    projections(book, author, "sale delete")

    update(book, name: "renamed#{@token}", summary: "changedsummary#{@token}")
    projections(book, author, "book edit")
    search_is("title#{@token} summary#{@token}", [], "old book fields removed")
    search_is("renamed#{@token} changedsummary#{@token}", [ book.id ], "updated book fields indexed")

    outage_checks(book, review)
    @created.grep(Review).select(&:persisted?).each { |record| destroy(record) }
    destroy(book)
    search_is("renamed#{@token} paged#{@token}", [ other.id ], "deleted book and its review documents removed")
    check("rankings after book deletion") do
      CachedRankings.rated.map(&:attributes) == TopRatedBooksQuery.new.call.map(&:attributes) &&
        CachedRankings.selling.map(&:attributes) == TopSellingBooksQuery.new.call.map(&:attributes)
    end
    @output.puts "PASS: full application correctness verification"
  ensure
    # Only this invocation's records are removed; never reset the assignment DB.
    @created.reverse_each { |record| record.destroy! if record.persisted? }
  end

  private

  def check(label)
    raise "FAIL: #{label}" unless yield

    @output.puts "PASS: #{label}"
  end

  def create(model, attributes)
    collection = "/#{model.table_name}"
    mutate(:post, collection, "#{collection}/new", model.model_name.param_key => attributes)
    record = model.find(@session.response.location.split("/").last)
    @created << record
    record
  end

  def update(record, attributes)
    path = "/#{record.class.table_name}/#{record.id}"
    mutate(:patch, path, "#{path}/edit", record.model_name.param_key => attributes)
    record.reload
  end

  def destroy(record)
    path = "/#{record.class.table_name}/#{record.id}"
    mutate(:delete, path, path, {})
    raise "FAIL: #{path} was not deleted" if record.class.exists?(record.id)

    @created.delete(record)
  end

  def mutate(method, path, form_path, params)
    @session.get(form_path)
    raise "FAIL: form #{form_path} status #{@session.response.status}" unless @session.response.successful?

    token = Nokogiri::HTML(@session.response.body).at_css('input[name="authenticity_token"]')&.[]("value")
    @session.public_send(method, path, params: params.merge(authenticity_token: token))
    raise "FAIL: #{method} #{path} status #{@session.response.status}" unless [ 302, 303 ].include?(@session.response.status)
  end

  def author_row(author)
    AuthorStatisticsQuery.new.call.find_by!(id: author.id)
  end

  def projections(book, author, label)
    check("#{label}: book average") { book.average_score == (book.reviews.average(:score) || 0) }
    check("#{label}: top rated") { CachedRankings.rated.map(&:attributes) == TopRatedBooksQuery.new.call.map(&:attributes) }
    check("#{label}: top selling") { CachedRankings.selling.map(&:attributes) == TopSellingBooksQuery.new.call.map(&:attributes) }
    check("#{label}: author overview") do
      author_row(author).attributes == AuthorStatisticsQuery.new({}, cache: false).call.find_by!(id: author.id).attributes
    end
    [ "/books/#{book.id}", "/reports/author-statistics", "/reports/top-rated-books", "/reports/top-selling-books" ].each do |path|
      @session.get(path)
      check("#{label}: GET #{path}") { @session.response.successful? }
    end
  end

  def search(query, **options)
    service = SearchService.new(query: query, page: 1, **options)
    result = service.call
    raise "FAIL: expected actual OpenSearch backend" unless service.backend == :opensearch

    result
  end

  def search_is(query, ids, label)
    check(label) { search(query).records.map(&:id).sort == ids.sort }
    @session.get("/book-search", params: { q: query })
    check("#{label}: search page") { @session.response.successful? }
  end

  def outage_checks(book, review)
    old_redis, old_search = ENV.values_at("REDIS_URL", "OPENSEARCH_URL")
    original_score = book.average_score
    ENV["REDIS_URL"] = "redis://127.0.0.1:1/0"
    ENV["OPENSEARCH_URL"] = "http://127.0.0.1:1"
    ReadCache.store = nil
    update(review, score: 4, review_text: "recovered#{@token}")
    check("both outages: DB write and fresh average succeed") { book.average_score != original_score }
    service = SearchService.new(query: "changedsummary#{@token}", page: 1)
    check("OpenSearch outage: summary-only fallback") { service.call.records.map(&:id) == [ book.id ] && service.backend == :postgresql }
    check("fallback excludes title/review-only matches") { SearchService.new(query: "renamed#{@token} recovered#{@token}", page: 1).call.records.empty? }
    ENV["REDIS_URL"], ENV["OPENSEARCH_URL"] = old_redis, old_search
    ReadCache.store = nil
    check("Redis recovery cannot reuse a stale pre-outage value") { book.average_score == book.reviews.average(:score) }
    Search::Indexer.new.reindex!(output: @output)
    search_is("recovered#{@token}", [ book.id ], "manual reindex repairs a failed synchronization")
  ensure
    ENV["REDIS_URL"], ENV["OPENSEARCH_URL"] = old_redis, old_search
    ReadCache.store = nil
  end
end
