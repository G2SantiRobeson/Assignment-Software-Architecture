module CacheKeys
  TOP_RATED = "top_rated_books:v1".freeze
  TOP_SELLING = "top_selling_books:v1".freeze

  def self.author(id)
    "authors_overview:v1:author:#{id}"
  end

  def self.average(id)
    "book_average_score:v1:#{id}"
  end

  def self.versioned(key, version)
    "#{key}:revision:#{version}"
  end
end
