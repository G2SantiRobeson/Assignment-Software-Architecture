class BookSummarySearchQuery
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100
  MAX_QUERY_LENGTH = 500
  MAX_TOKENS = 50

  class Page
    attr_reader :records, :current_page, :total_pages, :total_count, :per_page, :query

    alias_method :q, :query

    def initialize(records:, current_page:, total_pages:, total_count:, per_page:, query:)
      @records = records
      @current_page = current_page
      @total_pages = total_pages
      @total_count = total_count
      @per_page = per_page
      @query = query
    end

    def prev_page
      current_page - 1 if current_page > 1
    end

    alias_method :previous_page, :prev_page

    def next_page
      current_page + 1 if current_page < total_pages
    end

    def query_params
      { q: query }
    end

    def params_for_page(page_number)
      query_params.merge(page: page_number)
    end
  end

  def initialize(query:, page:, per_page: DEFAULT_PER_PAGE)
    bounded_query = query.to_s.strip[0, MAX_QUERY_LENGTH]
    @tokens = bounded_query
      .split(/\s+/)
      .reject(&:blank?)
      .uniq { |token| token.downcase }
      .first(MAX_TOKENS)
    @query = @tokens.join(" ")
    @requested_page = positive_integer(page) || 1
    requested_per_page = positive_integer(per_page) || DEFAULT_PER_PAGE
    @per_page = [ requested_per_page, MAX_PER_PAGE ].min
  end

  def call
    relation = matching_books
    total_count = relation.except(:limit, :offset, :order).count
    total_pages = (total_count.to_f / @per_page).ceil
    current_page = total_pages.positive? ? [ @requested_page, total_pages ].min : 1
    offset = (current_page - 1) * @per_page

    Page.new(
      records: relation.limit(@per_page).offset(offset),
      current_page: current_page,
      total_pages: total_pages,
      total_count: total_count,
      per_page: @per_page,
      query: @query
    )
  end

  private

  def matching_books
    return Book.none if tokens.empty?

    predicates = tokens.map do |token|
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(token)}%"
      Book.arel_table[:summary].matches(pattern, nil, false)
    end

    Book
      .where(predicates.reduce { |combined, predicate| combined.or(predicate) })
      .preload(:author)
      .order(Arel.sql("LOWER(books.name) ASC"), :id)
  end

  def tokens
    @tokens
  end

  def positive_integer(value)
    parsed = Integer(value.to_s, 10, exception: false)
    parsed if parsed&.positive?
  end
end
