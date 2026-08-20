class TopSellingBooksQuery
  BOOK_TOTALS_SQL = <<~SQL.squish.freeze
    SELECT sales.book_id,
           SUM(sales.sales)::bigint AS total_sales
      FROM sales
     GROUP BY sales.book_id
  SQL

  AUTHOR_TOTALS_SQL = <<~SQL.squish.freeze
    SELECT books.author_id,
           SUM(sales.sales)::bigint AS author_total_sales
      FROM books
      INNER JOIN sales ON sales.book_id = books.id
     GROUP BY books.author_id
  SQL

  PUBLICATION_YEAR_RANKINGS_SQL = <<~SQL.squish.freeze
    SELECT annual_book_sales.book_id,
           annual_book_sales.year,
           annual_book_sales.annual_sales,
           ROW_NUMBER() OVER (
             PARTITION BY annual_book_sales.year
             ORDER BY annual_book_sales.annual_sales DESC,
                      LOWER(ranking_books.name) ASC,
                      annual_book_sales.book_id ASC
           ) AS annual_rank
      FROM (
        SELECT sales.book_id,
               sales.year,
               SUM(sales.sales)::bigint AS annual_sales
          FROM sales
         GROUP BY sales.book_id, sales.year
      ) annual_book_sales
      INNER JOIN books ranking_books ON ranking_books.id = annual_book_sales.book_id
  SQL

  def call
    Book
      .joins(:author)
      .joins("LEFT JOIN (#{BOOK_TOTALS_SQL}) book_sales_statistics ON book_sales_statistics.book_id = books.id")
      .joins("LEFT JOIN (#{AUTHOR_TOTALS_SQL}) author_sales_statistics ON author_sales_statistics.author_id = books.author_id")
      .joins(
        "LEFT JOIN (#{PUBLICATION_YEAR_RANKINGS_SQL}) publication_year_rankings " \
          "ON publication_year_rankings.book_id = books.id " \
          "AND publication_year_rankings.year = EXTRACT(YEAR FROM books.date_of_publication)::integer"
      )
      .select(
        "books.*",
        "authors.name AS author_name",
        "COALESCE(book_sales_statistics.total_sales, 0)::bigint AS total_sales",
        "COALESCE(author_sales_statistics.author_total_sales, 0)::bigint AS author_total_sales",
        "(COALESCE(publication_year_rankings.annual_rank, 0) BETWEEN 1 AND 5) AS top_five_in_publication_year",
        "publication_year_rankings.annual_sales AS publication_year_sales",
        "publication_year_rankings.annual_rank AS publication_year_rank"
      )
      .order(
        Arel.sql(
          "COALESCE(book_sales_statistics.total_sales, 0) DESC, " \
            "LOWER(books.name) ASC, books.id ASC"
        )
      )
      .limit(50)
  end
end
