module Search
  class OpenSearchBackend < BookSummarySearchQuery
    class Unavailable < StandardError; end

    def initialize(client: nil, **options)
      super(**options)
      @client = client
    end

    def call
      return super if @query.blank?

      response = execute(0)
      count = response.fetch("aggregations").fetch("unique_books").fetch("value").to_i
      pages = (count.to_f / @per_page).ceil
      page = pages.positive? ? [ @requested_page, pages ].min : 1
      response = execute((page - 1) * @per_page) if page > 1
      ids = response.fetch("hits").fetch("hits").map { |hit| hit.fetch("_source").fetch("book_id").to_i }.uniq
      books = Book.where(id: ids).preload(:author).index_by(&:id)
      Page.new(records: ids.filter_map { |id| books[id] }, current_page: page,
        total_pages: pages, total_count: count, per_page: @per_page, query: @query)
    end

    private

    def execute(offset)
      response = (@client ||= Connection.client).search(index: Connection.index, body: {
        from: offset, size: @per_page, _source: [ "book_id" ],
        query: { multi_match: { query: @query, fields: [ "title^2", "summary", "review_text" ], operator: "or" } },
        collapse: { field: "book_id" }, sort: [ { _score: "desc" }, { book_id: "asc" } ],
        aggs: { unique_books: { cardinality: { field: "book_id", precision_threshold: 40_000 } } }
      })
      raise Unavailable, "incomplete search response" if response["timed_out"] || response.dig("_shards", "failed").to_i.positive?

      response
    rescue StandardError => error
      # Only the external call is rescued; database and application errors are
      # not disguised as a search outage.
      raise Unavailable, error.class.name
    end
  end
end
