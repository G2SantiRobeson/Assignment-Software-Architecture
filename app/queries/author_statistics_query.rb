class AuthorStatisticsQuery
  BOOK_STATISTICS_SQL = <<~SQL.squish.freeze
    SELECT books.author_id,
           COUNT(*)::bigint AS published_books_count
      FROM books
     GROUP BY books.author_id
  SQL

  REVIEW_STATISTICS_SQL = <<~SQL.squish.freeze
    SELECT books.author_id,
           AVG(reviews.score)::numeric AS average_score
      FROM books
      INNER JOIN reviews ON reviews.book_id = books.id
     GROUP BY books.author_id
  SQL

  SALES_STATISTICS_SQL = <<~SQL.squish.freeze
    SELECT books.author_id,
           SUM(sales.sales)::bigint AS total_sales
      FROM books
      INNER JOIN sales ON sales.book_id = books.id
     GROUP BY books.author_id
  SQL

  PUBLISHED_BOOKS_EXPRESSION = "COALESCE(author_book_statistics.published_books_count, 0)".freeze
  AVERAGE_SCORE_EXPRESSION = "COALESCE(author_review_statistics.average_score, 0)".freeze
  TOTAL_SALES_EXPRESSION = "COALESCE(author_sales_statistics.total_sales, 0)".freeze

  SORT_EXPRESSIONS = {
    "author" => "LOWER(authors.name)",
    "published_books" => PUBLISHED_BOOKS_EXPRESSION,
    "average_score" => AVERAGE_SCORE_EXPRESSION,
    "total_sales" => TOTAL_SALES_EXPRESSION
  }.freeze

  SORT_ALIASES = {
    "author_name" => "author",
    "name" => "author",
    "book_count" => "published_books",
    "books_count" => "published_books",
    "published_books_count" => "published_books"
  }.freeze

  DIRECTIONS = %w[asc desc].freeze

  # Every complete order clause is a constant. Request parameters only select
  # a key in this table; they are never interpolated into SQL.
  SORT_CLAUSES = {
    [ "author", "asc" ] => Arel.sql("LOWER(authors.name) ASC, authors.id ASC"),
    [ "author", "desc" ] => Arel.sql("LOWER(authors.name) DESC, authors.id ASC"),
    [ "published_books", "asc" ] => Arel.sql("COALESCE(author_book_statistics.published_books_count, 0) ASC, authors.id ASC"),
    [ "published_books", "desc" ] => Arel.sql("COALESCE(author_book_statistics.published_books_count, 0) DESC, authors.id ASC"),
    [ "average_score", "asc" ] => Arel.sql("COALESCE(author_review_statistics.average_score, 0) ASC, authors.id ASC"),
    [ "average_score", "desc" ] => Arel.sql("COALESCE(author_review_statistics.average_score, 0) DESC, authors.id ASC"),
    [ "total_sales", "asc" ] => Arel.sql("COALESCE(author_sales_statistics.total_sales, 0) ASC, authors.id ASC"),
    [ "total_sales", "desc" ] => Arel.sql("COALESCE(author_sales_statistics.total_sales, 0) DESC, authors.id ASC")
  }.freeze

  def initialize(params = {})
    raw_params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    @params = raw_params.stringify_keys
  end

  def call
    scope = Author
      .joins("LEFT JOIN (#{BOOK_STATISTICS_SQL}) author_book_statistics ON author_book_statistics.author_id = authors.id")
      .joins("LEFT JOIN (#{REVIEW_STATISTICS_SQL}) author_review_statistics ON author_review_statistics.author_id = authors.id")
      .joins("LEFT JOIN (#{SALES_STATISTICS_SQL}) author_sales_statistics ON author_sales_statistics.author_id = authors.id")
      .select(
        "authors.*",
        Arel.sql("#{PUBLISHED_BOOKS_EXPRESSION}::bigint AS published_books_count"),
        Arel.sql("#{AVERAGE_SCORE_EXPRESSION}::numeric AS average_score"),
        Arel.sql("#{TOTAL_SALES_EXPRESSION}::bigint AS total_sales")
      )

    scope = filter_author(scope)
    scope = filter_numeric_statistics(scope)

    scope.order(SORT_CLAUSES.fetch([ sort_key, sort_direction ]))
  end

  private

  def filter_author(scope)
    value = @params["author"].to_s.strip
    return scope if value.blank?

    escaped = ActiveRecord::Base.sanitize_sql_like(value)
    scope.where("authors.name ILIKE ?", "%#{escaped}%")
  end

  def filter_numeric_statistics(scope)
    if (value = parsed_number("published_books_min", :integer))
      scope = scope.where("COALESCE(author_book_statistics.published_books_count, 0) >= ?", value)
    end
    if (value = parsed_number("published_books_max", :integer))
      scope = scope.where("COALESCE(author_book_statistics.published_books_count, 0) <= ?", value)
    end
    if (value = parsed_number("average_score_min", :decimal))
      scope = scope.where("COALESCE(author_review_statistics.average_score, 0) >= ?", value)
    end
    if (value = parsed_number("average_score_max", :decimal))
      scope = scope.where("COALESCE(author_review_statistics.average_score, 0) <= ?", value)
    end
    if (value = parsed_number("total_sales_min", :integer))
      scope = scope.where("COALESCE(author_sales_statistics.total_sales, 0) >= ?", value)
    end
    if (value = parsed_number("total_sales_max", :integer))
      scope = scope.where("COALESCE(author_sales_statistics.total_sales, 0) <= ?", value)
    end

    scope
  end

  def parsed_number(key, type)
    value = @params[key].to_s.strip
    return if value.blank?

    case type
    when :integer
      Integer(value, 10, exception: false)
    when :decimal
      decimal = BigDecimal(value, exception: false)
      decimal if decimal&.finite?
    end
  end

  def sort_key
    requested_sort = @params.fetch("sort", "author").to_s
    canonical_sort = SORT_ALIASES.fetch(requested_sort, requested_sort)
    SORT_EXPRESSIONS.key?(canonical_sort) ? canonical_sort : "author"
  end

  def sort_direction
    requested_direction = @params.fetch("direction", "asc").to_s.downcase
    DIRECTIONS.include?(requested_direction) ? requested_direction : "asc"
  end
end
