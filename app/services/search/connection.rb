module Search
  module Connection
    def self.enabled?
      ENV.fetch("SEARCH_ENABLED", "false") == "true"
    end

    def self.index
      ENV.fetch("OPENSEARCH_INDEX", "book_reviews_#{Rails.env}_v1")
    end

    def self.client(timeout: 2)
      OpenSearch::Client.new(
        url: ENV.fetch("OPENSEARCH_URL", "http://localhost:9200"),
        retry_on_failure: false,
        transport_options: { request: { open_timeout: 0.5, timeout: timeout } }
      )
    end
  end
end
