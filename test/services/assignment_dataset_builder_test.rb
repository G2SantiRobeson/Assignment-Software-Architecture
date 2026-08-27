# frozen_string_literal: true

require "test_helper"

class AssignmentDatasetBuilderTest < ActiveSupport::TestCase
  class FakeImporter
    def call(author_limit:, book_limit:)
      authors = [
        {
          open_library_key: "/authors/OL1A",
          name: "Imported Author",
          date_of_birth: Date.new(1970, 1, 1),
          short_description: "Imported biography"
        }
      ].first(author_limit)
      books = [
        {
          open_library_key: "/works/OL1W",
          author_key: "/authors/OL1A",
          name: "Imported Book",
          summary: nil,
          date_of_publication: nil
        }
      ].first(book_limit)

      OpenLibraryImporter::Result.new(authors: authors, books: books, warnings: [ "partial fixture import" ])
    end
  end

  class CompleteAuthorsSparseBooksImporter
    def call(author_limit:, book_limit:)
      authors = 2.times.map do |index|
        { open_library_key: "/authors/OL#{index + 1}A", name: "Imported Author #{index + 1}" }
      end.first(author_limit)
      books = [ {
        open_library_key: "/works/OL1W",
        author_key: "/authors/OL1A",
        name: "Imported Book",
        date_of_publication: Date.new(2000, 1, 1)
      } ].first(book_limit)
      OpenLibraryImporter::Result.new(authors: authors, books: books, warnings: [], skipped_records: 0)
    end
  end

  class DuplicateLeadingAuthorsImporter
    def call(author_limit:, book_limit:)
      authors = [
        { open_library_key: "/authors/OL1A", name: "First Imported Author" },
        { open_library_key: "/authors/OL1A", name: "Duplicate First Author" },
        { open_library_key: "/authors/OL2A", name: "Second Imported Author" }
      ]
      books = [
        {
          open_library_key: "/works/OL1W",
          author_key: "/authors/OL1A",
          name: "First Imported Book",
          date_of_publication: Date.new(2000, 1, 1)
        },
        {
          open_library_key: "/works/OL2W",
          author_key: "/authors/OL2A",
          name: "Second Imported Book",
          date_of_publication: Date.new(2001, 1, 1)
        }
      ]

      OpenLibraryImporter::Result.new(
        authors: authors,
        books: books.first(book_limit),
        warnings: [],
        skipped_records: 0
      )
    end
  end

  class LatePublicationImporter
    def call(author_limit:, book_limit:)
      authors = [ { open_library_key: "/authors/OL9999A", name: "Late Imported Author" } ].first(author_limit)
      books = [ {
        open_library_key: "/works/OL9999W",
        author_key: "/authors/OL9999A",
        name: "Late Imported Book",
        date_of_publication: Date.new(9999, 1, 1)
      } ].first(book_limit)

      OpenLibraryImporter::Result.new(authors: authors, books: books, warnings: [], skipped_records: 0)
    end
  end

  test "uses imported records first and fills only deficits deterministically" do
    result = builder.call

    assert_equal 1, result.open_library_authors
    assert_equal 1, result.open_library_books
    assert_equal 1, result.fallback_authors
    assert_equal 2, result.fallback_books
    assert_equal 2, Author.count
    assert_equal 3, Book.count
    imported_book = Book.find_by!(open_library_key: "/works/OL1W")
    assert_equal Date.new(2000, 1, 1), imported_book.date_of_publication
    assert_match(/synthetic summary/i, imported_book.summary)
    assert_operator result.minimum_reviews_per_book, :>=, 1
    assert_operator result.maximum_reviews_per_book, :<=, 10
    assert_equal 5, result.minimum_sale_years_per_book
    assert_equal 1, Sale.where(year: 2000).where(book: Book.find_by!(open_library_key: "/works/OL1W")).count

    Book.find_each do |book|
      assert_equal book.sales.sum(:sales), book.number_of_sales
    end

    verification = SeedDataVerifier.verify!(minimum_authors: 2, minimum_books: 3, minimum_sale_years: 5)
    assert_equal Review.count, verification[:reviews]
  end

  test "transactional reset makes repeated builds non-accumulating" do
    first = builder.call
    first_counts = [ Author.count, Book.count, Review.count, Sale.count ]
    second = builder.call

    assert_equal first_counts, [ Author.count, Book.count, Review.count, Sale.count ]
    assert_equal first.reviews, second.reviews
    assert_equal first.sales, second.sales
  end

  test "disabled importer creates the full fallback minimum" do
    result = AssignmentDatasetBuilder.new(
      importer: nil,
      author_target: 2,
      book_target: 3,
      sale_years: 5,
      random_seed: 7,
      logger: nil
    ).call

    assert_equal 0, result.open_library_authors
    assert_equal 0, result.open_library_books
    assert_equal 2, result.fallback_authors
    assert_equal 3, result.fallback_books
  end

  test "synthetic books never assert authorship by a real imported author" do
    result = AssignmentDatasetBuilder.new(
      importer: CompleteAuthorsSparseBooksImporter.new,
      author_target: 2,
      book_target: 3,
      sale_years: 5,
      random_seed: 7,
      logger: nil
    ).call

    fallback_books = Book.where(open_library_key: nil)
    assert_equal 2, result.open_library_authors
    assert_equal 1, result.fallback_authors
    assert_equal 2, fallback_books.count
    assert fallback_books.all? { |book| book.author.open_library_key.nil? }
    assert_equal 3, Author.count
  end

  test "deduplicates all imported authors before deciding whether the target needs fallback" do
    result = AssignmentDatasetBuilder.new(
      importer: DuplicateLeadingAuthorsImporter.new,
      author_target: 2,
      book_target: 2,
      sale_years: 5,
      random_seed: 7,
      logger: nil
    ).call

    assert_equal 2, result.open_library_authors
    assert_equal 0, result.fallback_authors
    assert_equal [ "/authors/OL1A", "/authors/OL2A" ], Author.order(:open_library_key).pluck(:open_library_key)
    assert_equal 2, result.open_library_books
    assert_equal 0, result.fallback_books
  end

  test "publication-year sales deliberately include deterministic ties" do
    result = AssignmentDatasetBuilder.new(
      importer: nil,
      author_target: 2,
      book_target: 42,
      sale_years: 5,
      random_seed: 7,
      logger: nil
    ).call

    publication_sales = Sale.joins(:book)
      .where("sales.year = EXTRACT(YEAR FROM books.date_of_publication)::integer")
    tied_groups = publication_sales.group(:year, :sales).having("COUNT(*) > 1").count

    assert_equal 42, result.fallback_books
    assert tied_groups.any?
  end

  test "replaces an imported date too late for forward sale years with the synthetic date fallback" do
    result = AssignmentDatasetBuilder.new(
      importer: LatePublicationImporter.new,
      author_target: 1,
      book_target: 1,
      sale_years: 5,
      random_seed: 7,
      logger: nil
    ).call
    book = Book.find_by!(open_library_key: "/works/OL9999W")

    assert_equal 1, result.open_library_books
    assert_equal AssignmentDatasetBuilder::SYNTHETIC_PUBLICATION_DATE, book.date_of_publication
    assert_equal (2000..2004).to_a, book.sales.order(:year).pluck(:year)

    verification = SeedDataVerifier.verify!(minimum_authors: 1, minimum_books: 1, minimum_sale_years: 5)
    assert_equal 0, verification[:sales_before_publication]
  end

  test "rejects a sale-year count that cannot fit in the supported year range" do
    error = assert_raises(ArgumentError) do
      AssignmentDatasetBuilder.new(
        importer: nil,
        author_target: 1,
        book_target: 1,
        sale_years: 10_000,
        logger: nil
      )
    end

    assert_equal "sale_years cannot exceed 9999", error.message
  end

  private

  def builder
    AssignmentDatasetBuilder.new(
      importer: FakeImporter.new,
      author_target: 2,
      book_target: 3,
      sale_years: 5,
      random_seed: 7,
      logger: nil
    )
  end
end
