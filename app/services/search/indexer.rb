module Search
  class Indexer
    DEFINITION = {
      settings: { number_of_shards: 1, number_of_replicas: 0 },
      mappings: { dynamic: "strict", properties: {
        document_type: { type: "keyword" }, book_id: { type: "keyword" }, review_id: { type: "keyword" },
        title: { type: "text" }, summary: { type: "text" }, review_text: { type: "text" }
      } }
    }.freeze

    def initialize(client: nil)
      @client = client
    end

    def synchronize(model_name, id)
      return unless Connection.enabled?

      # Serialize competing synchronizers and reload committed data while holding
      # a DB advisory lock. A delayed callback cannot overwrite a newer value.
      ApplicationRecord.transaction do
        lock = model_name == "Book" ? 7301 : 7302
        sql = ApplicationRecord.sanitize_sql_array([ "SELECT pg_advisory_xact_lock(?, ?)", lock, Integer(id) % 2_147_483_647 ])
        ApplicationRecord.connection.execute(sql)
        record = model_name.constantize.find_by(id: id)
        ensure_index!
        if record
          client.index(index: Connection.index, id: document_id(record), body: document(record), refresh: true)
        elsif model_name == "Book"
          client.delete_by_query(index: Connection.index, refresh: true, body: { query: { term: { book_id: id.to_s } } })
        else
          client.delete(index: Connection.index, id: "review:#{id}", refresh: true, ignore: 404)
        end
      end
    rescue StandardError => error
      Rails.logger.warn("OpenSearch sync failed for #{model_name} #{id} (#{error.class}); run bin/rails search:reindex")
      false
    end

    def ensure_index!
      return if client.indices.exists?(index: Connection.index)

      client.indices.create(index: Connection.index, body: DEFINITION)
    rescue OpenSearch::Transport::Transport::Errors::BadRequest => error
      raise unless error.message.include?("resource_already_exists_exception")
    end

    # Explicit maintenance task; pause application writes during rebuilding.
    # Errors propagate so a partial rebuild cannot be reported as successful.
    def reindex!(output: $stdout)
      raise "SEARCH_ENABLED must be true" unless Connection.enabled?

      # Administrative bulk work needs a larger budget than a normal request.
      @client ||= Connection.client(timeout: 60)

      index = Connection.index
      raise "Unsafe index name" unless index.match?(/\A[a-z0-9][a-z0-9_-]*\z/)

      client.indices.delete(index: index) if client.indices.exists?(index: index)
      ensure_index!
      [ Book, Review ].each do |model|
        count = 0
        model.find_in_batches(batch_size: 500) do |batch|
          body = batch.flat_map { |record| [ { index: { _index: index, _id: document_id(record) } }, document(record) ] }
          response = client.bulk(body: body)
          raise "Bulk indexing failed for #{model.name}; inspect OpenSearch logs" if response["errors"]

          count += batch.size
          output.puts "Indexed #{count} #{model.name} documents"
        end
      end
      client.indices.refresh(index: index)
      output.puts "PASS: rebuilt #{index} from PostgreSQL"
    end

    private

    def client
      @client ||= Connection.client
    end

    def document_id(record)
      "#{record.class.name.downcase}:#{record.id}"
    end

    def document(record)
      if record.is_a?(Book)
        { document_type: "book", book_id: record.id.to_s, title: record.name, summary: record.summary }
      else
        { document_type: "review", review_id: record.id.to_s, book_id: record.book_id.to_s, review_text: record.review_text }
      end
    end
  end
end
