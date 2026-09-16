namespace :search do
  desc "Initialize the search projection only when its index does not yet exist"
  task ensure_index: :environment do
    if Search::Connection.enabled? && !Search::Connection.client.indices.exists?(index: Search::Connection.index)
      Search::Indexer.new.reindex!
    end
  end

  desc "Rebuild the optional OpenSearch projection from PostgreSQL (pause writes first)"
  task reindex: :environment do
    Search::Indexer.new.reindex!
  end
end
