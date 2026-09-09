class SearchService
  attr_reader :backend

  def initialize(**options)
    @options = options
  end

  def call
    @backend = :postgresql
    if Search::Connection.enabled?
      begin
        result = Search::OpenSearchBackend.new(**@options).call
        @backend = :opensearch
        return result
      rescue Search::OpenSearchBackend::Unavailable => error
        Rails.logger.warn("OpenSearch search failed (#{error.message}); using summary-only PostgreSQL search")
      end
    end
    BookSummarySearchQuery.new(**@options).call
  end
end
