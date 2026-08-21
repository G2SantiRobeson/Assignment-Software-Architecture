# frozen_string_literal: true

# Performs database-side cardinality and integrity checks after seeding. It
# raises rather than allowing an incomplete dataset to appear successful.
class SeedDataVerifier
  class VerificationError < StandardError; end

  def self.verify!(...)
    new(...).verify!
  end

  def initialize(minimum_authors: 50, minimum_books: 300, minimum_sale_years: 5)
    @minimum_authors = minimum_authors
    @minimum_books = minimum_books
    @minimum_sale_years = minimum_sale_years
  end

  def verify!
    metrics = collect_metrics
    failures = []
    failures << "authors #{metrics[:authors]} < #{@minimum_authors}" if metrics[:authors] < @minimum_authors
    failures << "books #{metrics[:books]} < #{@minimum_books}" if metrics[:books] < @minimum_books
    failures << "#{metrics[:books_without_author]} books have no author" if metrics[:books_without_author].positive?
    failures << "review count per book is outside 1..10" unless valid_review_range?(metrics)
    if metrics[:minimum_sale_years_per_book] < @minimum_sale_years
      failures << "a book has fewer than #{@minimum_sale_years} distinct sale years"
    end
    failures << "duplicate Sale(book_id, year) groups exist" if metrics[:duplicate_sale_years].positive?
    failures << "invalid review values exist" if metrics[:invalid_reviews].positive?
    failures << "invalid sale values exist" if metrics[:invalid_sales].positive?
    failures << "sales exist before a book's publication year" if metrics[:sales_before_publication].positive?
    failures << "cached book sales differ from yearly Sale sums" if metrics[:sales_total_mismatches].positive?
    if metrics[:books_without_searchable_summary].positive?
      failures << "#{metrics[:books_without_searchable_summary]} books lack a searchable summary"
    end

    raise VerificationError, failures.join("; ") if failures.any?

    metrics
  end

  private

  def collect_metrics
    review_counts = Book.left_joins(:reviews).group("books.id").count("reviews.id").values
    sale_year_counts = Book.left_joins(:sales).group("books.id").count("DISTINCT sales.year").values

    {
      authors: Author.count,
      books: Book.count,
      reviews: Review.count,
      sales: Sale.count,
      books_without_author: Book.where(author_id: nil).count,
      minimum_reviews_per_book: review_counts.min || 0,
      maximum_reviews_per_book: review_counts.max || 0,
      minimum_sale_years_per_book: sale_year_counts.min || 0,
      duplicate_sale_years: Sale.group(:book_id, :year).having("COUNT(*) > 1").count.length,
      invalid_reviews: Review.where("score NOT BETWEEN 1 AND 5 OR up_votes < 0").count,
      invalid_sales: Sale.where("year NOT BETWEEN 1 AND 9999 OR sales < 0").count,
      sales_before_publication: Sale.joins(:book)
        .where("sales.year < EXTRACT(YEAR FROM books.date_of_publication)::integer").count,
      books_without_searchable_summary: Book.where("summary IS NULL OR BTRIM(summary) = ''").count,
      sales_total_mismatches: sales_total_mismatch_count
    }
  end

  def sales_total_mismatch_count
    Book.left_joins(:sales)
      .select("books.id")
      .group("books.id")
      .having("books.number_of_sales <> COALESCE(SUM(sales.sales), 0)")
      .length
  end

  def valid_review_range?(metrics)
    metrics[:books].positive? &&
      metrics[:minimum_reviews_per_book] >= 1 &&
      metrics[:maximum_reviews_per_book] <= 10
  end
end
