class TopRatedBooksQuery
  REVIEW_DETAILS_SQL = <<~SQL.squish.freeze
    SELECT ranked_reviews.book_id,
           AVG(ranked_reviews.score)::numeric AS average_score,
           COUNT(*)::bigint AS review_count,
           MAX(ranked_reviews.review_text) FILTER (WHERE ranked_reviews.highest_rank = 1) AS highest_rated_review,
           MAX(ranked_reviews.score) FILTER (WHERE ranked_reviews.highest_rank = 1) AS highest_review_score,
           MAX(ranked_reviews.review_text) FILTER (WHERE ranked_reviews.lowest_rank = 1) AS lowest_rated_review,
           MAX(ranked_reviews.score) FILTER (WHERE ranked_reviews.lowest_rank = 1) AS lowest_review_score
      FROM (
        SELECT reviews.book_id,
               reviews.review_text,
               reviews.score,
               ROW_NUMBER() OVER (
                 PARTITION BY reviews.book_id
                 ORDER BY reviews.score DESC, reviews.id ASC
               ) AS highest_rank,
               ROW_NUMBER() OVER (
                 PARTITION BY reviews.book_id
                 ORDER BY reviews.score ASC, reviews.id ASC
               ) AS lowest_rank
          FROM reviews
      ) ranked_reviews
     GROUP BY ranked_reviews.book_id
  SQL

  def call
    Book
      .joins(:author)
      .joins("INNER JOIN (#{REVIEW_DETAILS_SQL}) book_review_statistics ON book_review_statistics.book_id = books.id")
      .select(
        "books.*",
        "authors.name AS author_name",
        "book_review_statistics.average_score",
        "book_review_statistics.review_count",
        "book_review_statistics.highest_rated_review",
        "book_review_statistics.highest_review_score",
        "book_review_statistics.lowest_rated_review",
        "book_review_statistics.lowest_review_score"
      )
      .order(
        Arel.sql(
          "book_review_statistics.average_score DESC, " \
            "book_review_statistics.review_count DESC, " \
            "LOWER(books.name) ASC, books.id ASC"
        )
      )
      .limit(10)
  end
end
