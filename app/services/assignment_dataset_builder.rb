# frozen_string_literal: true

# Rebuilds the assignment dataset transactionally. Open Library supplies real
# author/book identity where available; deterministic local data fills only the
# remaining author/book deficits and all required reviews/yearly sales.
class AssignmentDatasetBuilder
  Result = Struct.new(
    :open_library_authors,
    :open_library_books,
    :fallback_authors,
    :fallback_books,
    :reviews,
    :sales,
    :minimum_reviews_per_book,
    :maximum_reviews_per_book,
    :minimum_sale_years_per_book,
    :skipped_open_library_records,
    :warnings,
    keyword_init: true
  ) do
    def to_h
      members.to_h { |member| [ member, public_send(member) ] }
    end
  end

  DEFAULT_AUTHOR_TARGET = 50
  DEFAULT_BOOK_TARGET = 300
  DEFAULT_SALE_YEARS = 5
  DEFAULT_RANDOM_SEED = 20_260_812
  MAX_SALE_YEAR = 9_999
  SYNTHETIC_PUBLICATION_DATE = Date.new(2000, 1, 1)

  def initialize(
    importer: OpenLibraryImporter.new,
    author_target: DEFAULT_AUTHOR_TARGET,
    book_target: DEFAULT_BOOK_TARGET,
    sale_years: DEFAULT_SALE_YEARS,
    random_seed: DEFAULT_RANDOM_SEED,
    logger: defined?(Rails) ? Rails.logger : nil
  )
    @importer = importer
    @author_target = positive_integer(author_target, "author_target")
    @book_target = positive_integer(book_target, "book_target")
    @sale_years = positive_integer(sale_years, "sale_years")
    raise ArgumentError, "sale_years cannot exceed #{MAX_SALE_YEAR}" if @sale_years > MAX_SALE_YEAR

    @random_seed = Integer(random_seed)
    @logger = logger
  end

  # reset: true is deliberate for this dedicated assignment application. The
  # delete-and-rebuild occurs in one transaction, so reruns cannot accumulate
  # reviews or sales and a failed rebuild rolls back to the previous dataset.
  def call(reset: true)
    raise ArgumentError, "only transactional reset mode is supported" unless reset

    imported = fetch_import
    result = nil

    ApplicationRecord.transaction do
      reset_assignment_tables!
      author_records, imported_author_count = create_authors!(imported.authors)
      book_records, imported_book_count = create_books!(imported.books, author_records)
      fallback_author_count = add_fallback_authors!(author_records)
      fallback_book_count, supplemental_author_count = add_fallback_books!(book_records, author_records)
      fallback_author_count += supplemental_author_count
      review_counts = create_reviews!(book_records)
      sale_year_counts = create_sales!(book_records)

      result = Result.new(
        open_library_authors: imported_author_count,
        open_library_books: imported_book_count,
        fallback_authors: fallback_author_count,
        fallback_books: fallback_book_count,
        reviews: review_counts.sum,
        sales: sale_year_counts.sum,
        minimum_reviews_per_book: review_counts.min || 0,
        maximum_reviews_per_book: review_counts.max || 0,
        minimum_sale_years_per_book: sale_year_counts.min || 0,
        skipped_open_library_records: imported.skipped_records.to_i,
        warnings: imported.warnings
      )
    end

    log_result(result)
    result
  end

  private

  def fetch_import
    return OpenLibraryImporter::Result.empty(warnings: [ "Open Library import disabled" ]) unless @importer

    @importer.call(author_limit: @author_target, book_limit: @book_target)
  rescue OpenLibraryImporter::Error => error
    OpenLibraryImporter::Result.empty(warnings: [ "Open Library import failed: #{error.message}" ])
  end

  def reset_assignment_tables!
    Sale.delete_all
    Review.delete_all
    Book.delete_all
    Author.delete_all
  end

  def create_authors!(source_authors)
    by_key = {}
    imported_count = 0

    Array(source_authors).each_with_index do |attributes, index|
      break if by_key.length >= @author_target

      key = attributes[:open_library_key].to_s.presence
      next unless key && !by_key.key?(key)

      author = Author.create!(
        open_library_key: key,
        name: attributes[:name].presence || "Open Library Author #{index + 1}",
        date_of_birth: attributes[:date_of_birth] || fallback_birth_date(index),
        country_of_origin: attributes[:country_of_origin].presence || "Unknown (synthetic fallback)",
        short_description: attributes[:short_description].presence ||
          "Biographical details were unavailable from Open Library; this description is synthetic seed data."
      )
      by_key[key] = author
      imported_count += 1
    end

    [ by_key, imported_count ]
  end

  def add_fallback_authors!(author_records)
    deficit = @author_target - author_records.length
    return 0 unless deficit.positive?

    deficit.times do |offset|
      ordinal = author_records.length + 1
      author = create_fallback_author!(ordinal)
      author_records["fallback:#{offset}"] = author
    end

    deficit
  end

  def create_books!(source_books, author_records)
    records = []
    seen_keys = {}

    Array(source_books).each do |attributes|
      break if records.length >= @book_target

      key = attributes[:open_library_key].to_s.presence
      author = author_records[attributes[:author_key]]
      next unless key && author && !seen_keys[key]

      records << Book.create!(
        open_library_key: key,
        author: author,
        name: attributes[:name].presence || "Untitled Open Library work",
        summary: attributes[:summary].presence || synthetic_summary(attributes[:name], author.name),
        date_of_publication: seed_publication_date(attributes[:date_of_publication]),
        number_of_sales: 0
      )
      seen_keys[key] = true
    end

    [ records, records.length ]
  end

  def add_fallback_books!(book_records, author_records)
    deficit = @book_target - book_records.length
    return [ 0, 0 ] unless deficit.positive?

    fallback_authors = author_records.filter_map do |key, author|
      author if key.start_with?("fallback:")
    end
    supplemental_author_count = 0
    if fallback_authors.empty?
      author = create_fallback_author!(author_records.length + 1)
      author_records["fallback:book-host"] = author
      fallback_authors << author
      supplemental_author_count = 1
    end

    deficit.times do |offset|
      ordinal = book_records.length + 1
      author = fallback_authors[offset % fallback_authors.length]
      title = format("Fallback Book %03d", ordinal)
      book_records << Book.create!(
        author: author,
        name: title,
        summary: synthetic_summary(title, author.name),
        date_of_publication: seed_publication_date(
          Date.new(1980 + (ordinal % 40), 1 + (ordinal % 12), 1)
        ),
        number_of_sales: 0
      )
    end

    [ deficit, supplemental_author_count ]
  end

  def create_reviews!(books)
    random = Random.new(@random_seed)
    now = Time.current
    rows = []
    counts = []

    books.each do |book|
      count = random.rand(1..10)
      counts << count
      count.times do |index|
        rows << {
          book_id: book.id,
          review_text: "Seed review #{index + 1} for #{book.name}.",
          score: random.rand(1..5),
          up_votes: random.rand(0..250),
          created_at: now,
          updated_at: now
        }
      end
    end

    Review.insert_all!(rows) if rows.any?
    counts
  end

  def create_sales!(books)
    random = Random.new(@random_seed ^ 0x5A1E5)
    now = Time.current
    rows = []
    counts = []

    books.each do |book|
      years = sale_year_range(book.date_of_publication.year)
      counts << years.length
      years.each_with_index do |year, year_index|
        rows << {
          book_id: book.id,
          year: year,
          # A shared publication-year value deliberately creates annual ties;
          # later years stay varied so lifetime totals remain useful to rank.
          sales: year_index.zero? ? 50_000 : random.rand(500..75_000),
          created_at: now,
          updated_at: now
        }
      end
    end

    Sale.insert_all!(rows) if rows.any?
    Book.refresh_number_of_sales_for!(books.map(&:id))
    counts
  end

  def sale_year_range(publication_year)
    unless publication_year.between?(1, latest_supported_publication_year)
      raise ArgumentError, "publication year cannot support #{@sale_years} forward sale years"
    end

    (publication_year...(publication_year + @sale_years)).to_a
  end

  def seed_publication_date(source_date)
    return source_date if source_date&.year&.between?(1, latest_supported_publication_year)

    Date.new([ SYNTHETIC_PUBLICATION_DATE.year, latest_supported_publication_year ].min, 1, 1)
  end

  def latest_supported_publication_year
    MAX_SALE_YEAR - @sale_years + 1
  end

  def fallback_birth_date(index)
    Date.new(1935 + (index % 55), 1 + (index % 12), 1 + (index % 27))
  end

  def create_fallback_author!(ordinal)
    Author.create!(
      name: format("Fallback Author %03d", ordinal),
      date_of_birth: fallback_birth_date(ordinal - 1),
      country_of_origin: "Unknown (synthetic fallback)",
      short_description: "Synthetic author created only to own synthetic fallback books without asserting false authorship."
    )
  end

  def synthetic_summary(title, author_name)
    "A synthetic summary for #{title.presence || 'this book'} by #{author_name}, used when Open Library did not provide a description."
  end

  def positive_integer(value, name)
    integer = Integer(value)
    raise ArgumentError, "#{name} must be positive" unless integer.positive?

    integer
  end

  def log_result(result)
    @logger&.info(
      "Seed dataset built: Open Library authors=#{result.open_library_authors}, " \
      "Open Library books=#{result.open_library_books}, fallback authors=#{result.fallback_authors}, " \
      "fallback books=#{result.fallback_books}, reviews=#{result.reviews}, sales=#{result.sales}"
    )
  end
end
