namespace :assignment4 do
  desc "Verify real database, Redis cache/session state and OpenSearch connectivity"
  task verify_dependencies: :environment do
    raise "PostgreSQL unavailable" unless ApplicationRecord.connection.select_value("SELECT 1") == 1
    if ReadCache.enabled?
      key = "edge-verification:#{SecureRandom.hex(8)}"
      ReadCache.fetch(key) { "shared-value" }
      raise "Cache value mismatch" unless ReadCache.fetch(key) { raise "Redis cache miss" } == "shared-value"
      ReadCache.store.delete(CacheKeys.versioned(key, 0))
    end
    if ENV["SESSION_STORE"] == "redis"
      redis = Redis.new(url: ENV.fetch("SESSION_REDIS_URL"))
      raise "No shared sessions found; run verify_http first" unless redis.scan_each(match: "book_reviews:sessions:*").any?
    end
    if Search::Connection.enabled?
      service = SearchService.new(query: "architecture", page: 1)
      service.call
      raise "Search fell back to PostgreSQL" unless service.backend == :opensearch
    end
    puts "PASS: PostgreSQL, configured shared cache/sessions and search"
  ensure
    redis&.close
  end

  desc "Add an idempotent load-test dataset without deleting existing domain data"
  task load_data: :environment do
    previous_search = ENV["SEARCH_ENABLED"]
    ENV["SEARCH_ENABLED"] = "false"
    ApplicationRecord.transaction do
      50.times do |i|
        author = Author.find_or_create_by!(name: "Edge Load Author #{i + 1}")
        6.times do |j|
          book = author.books.find_or_create_by!(name: "Edge Load Book #{i + 1}-#{j + 1}") do |record|
            record.summary = "Architecture of distributed systems, caching and search."
            record.date_of_publication = Date.new(2000, 1, 1)
          end
          5.times { |year| book.sales.find_or_create_by!(year: 2000 + year) { |sale| sale.sales = (i + 1) * 100 + j } }
          book.reviews.find_or_create_by!(review_text: "Architecture load fixture") { |review| review.score = 4; review.up_votes = 0 }
        end
      end
    end
    book = Book.joins(:author).find_by!(name: "Edge Load Book 1-1", authors: { name: "Edge Load Author 1" })
    unless book.image.attached?
      book.image.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "load-cover.png", content_type: "image/png")
    end
    ENV["SEARCH_ENABLED"] = previous_search
    Search::Indexer.new.reindex! if Search::Connection.enabled?
    puts({ book_path: "/books/#{book.id}", image_path: "/uploads/#{book.image.blob.key}.png", search_path: "/book-search?q=architecture", aggregation_path: "/reports/top-selling-books" }.to_json)
  ensure
    ENV["SEARCH_ENABLED"] = previous_search
  end
end
