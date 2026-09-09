class CachedRankings
  RATED_FIELDS = %w[average_score review_count highest_rated_review highest_review_score lowest_rated_review lowest_review_score].freeze
  SELLING_FIELDS = %w[total_sales author_total_sales top_five_in_publication_year publication_year_sales publication_year_rank].freeze

  def self.rated
    load(CacheKeys::TOP_RATED, TopRatedBooksQuery, RATED_FIELDS)
  end

  def self.selling
    load(CacheKeys::TOP_SELLING, TopSellingBooksQuery, SELLING_FIELDS)
  end

  def self.load(key, query, fields)
    rows = ReadCache.fetch(key) { query.new.call.map { |book| book.attributes.slice("id", *fields) } }
    books = Book.where(id: rows.pluck("id")).preload(:author).index_by(&:id)
    rows.filter_map do |row|
      book = books[row.fetch("id")]
      next unless book

      # Instantiate the same read-only aggregate shape as the existing queries,
      # but always hydrate mutable book/author fields from PostgreSQL in bulk.
      Book.instantiate(book.attributes.merge(row).merge("author_name" => book.author.name))
    end
  end
end
