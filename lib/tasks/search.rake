namespace :search do
  desc "Rebuild the optional OpenSearch projection from PostgreSQL (pause writes first)"
  task reindex: :environment do
    Search::Indexer.new.reindex!
  end
end
