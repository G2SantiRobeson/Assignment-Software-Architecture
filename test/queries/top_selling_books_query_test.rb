require "test_helper"

class TopSellingBooksQueryTest < ActiveSupport::TestCase
  test "calculates book and author totals once across multiple books and years" do
    author = create_author("Aggregate Author")
    first = create_book(author, "First", publication_year: 2020)
    second = create_book(author, "Second", publication_year: 2020)
    create_review(first, 5, "First review")
    create_review(first, 4, "Second review")
    create_review(first, 3, "Third review")
    create_review(second, 2, "Fourth review")
    create_review(second, 1, "Fifth review")
    create_sale(first, 2020, 100)
    create_sale(first, 2021, 50)
    create_sale(second, 2020, 25)

    rows = TopSellingBooksQuery.new.call.index_by(&:id)

    assert_equal 150, rows.fetch(first.id).total_sales
    assert_equal 25, rows.fetch(second.id).total_sales
    assert_equal 175, rows.fetch(first.id).author_total_sales
    assert_equal 175, rows.fetch(second.id).author_total_sales
    assert_equal author.name, rows.fetch(first.id).author_name
  end

  test "uses row number for exactly five deterministic winners when annual sales tie" do
    author = create_author("Tie Author")
    books = %w[Foxtrot Echo Delta Charlie Bravo Alpha].map do |name|
      book = create_book(author, name, publication_year: 2025)
      create_sale(book, 2025, 100)
      book
    end

    rows = TopSellingBooksQuery.new.call.index_by(&:id)
    ordered = books.sort_by { |book| [ book.name.downcase, book.id ] }

    ordered.each_with_index do |book, index|
      assert_equal index + 1, rows.fetch(book.id).publication_year_rank
      assert_equal(index < 5, rows.fetch(book.id).top_five_in_publication_year)
    end
  end

  test "checks sales from a book publication year rather than lifetime sales" do
    author = create_author("Publication Author")
    target = create_book(author, "Lifetime Leader", publication_year: 2030)
    create_sale(target, 2029, 10_000)
    create_sale(target, 2030, 1)

    5.times do |index|
      competitor = create_book(author, "Competitor #{index}", publication_year: 2020)
      create_sale(competitor, 2030, index + 2)
    end

    target_row = TopSellingBooksQuery.new.call.find { |row| row.id == target.id }

    assert_equal 10_001, target_row.total_sales
    assert_equal 1, target_row.publication_year_sales
    assert_equal 6, target_row.publication_year_rank
    assert_not target_row.top_five_in_publication_year
  end

  test "limits lifetime ranking to fifty with deterministic ties" do
    author = create_author("Many Books Author")
    books = 51.times.map do |index|
      book = create_book(author, format("Book %02d", 50 - index), publication_year: 2024)
      create_sale(book, 2024, 10)
      book
    end
    expected_ids = books.sort_by { |book| [ book.name.downcase, book.id ] }.first(50).map(&:id)

    assert_equal expected_ids, TopSellingBooksQuery.new.call.map(&:id)
  end

  test "uses book id to break identical-name ties in lifetime and annual rankings" do
    author = create_author("Identical Books Author")
    first = create_book(author, "Identical Name", publication_year: 2024)
    second = create_book(author, "Identical Name", publication_year: 2024)
    create_sale(first, 2024, 10)
    create_sale(second, 2024, 10)

    rows = TopSellingBooksQuery.new.call.to_a

    assert_equal [ first.id, second.id ], rows.map(&:id)
    assert_equal [ 1, 2 ], rows.map(&:publication_year_rank)
    assert rows.all?(&:top_five_in_publication_year)
  end

  private

  def create_author(name)
    Author.create!(name: name)
  end

  def create_book(author, name, publication_year:)
    Book.create!(
      author: author,
      name: name,
      summary: "Summary",
      date_of_publication: Date.new(publication_year, 1, 1)
    )
  end

  def create_sale(book, year, sales)
    Sale.create!(book: book, year: year, sales: sales)
  end

  def create_review(book, score, text)
    Review.create!(book: book, score: score, review_text: text, up_votes: 0)
  end
end
