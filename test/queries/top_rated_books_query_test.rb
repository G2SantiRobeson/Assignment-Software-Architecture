require "test_helper"

class TopRatedBooksQueryTest < ActiveSupport::TestCase
  test "ranks by average then review count then case-insensitive name and id" do
    author = create_author
    alpha = create_book(author, "Alpha")
    beta = create_book(author, "beta")
    gamma = create_book(author, "Gamma")
    no_reviews = create_book(author, "No Reviews")

    create_review(alpha, 5, "Alpha first")
    create_review(alpha, 5, "Alpha second")
    create_review(beta, 5, "Beta only")
    create_review(gamma, 4, "Gamma")

    rows = TopRatedBooksQuery.new.call.to_a

    assert_equal [ alpha, beta, gamma ].map(&:id), rows.map(&:id)
    assert_not_includes rows.map(&:id), no_reviews.id
    assert_equal BigDecimal("5"), rows.first.average_score
    assert_equal 2, rows.first.review_count
    assert_equal author.name, rows.first.author_name
  end

  test "uses the oldest review id to break equal highest and lowest review ties" do
    book = create_book(create_author, "Tied Reviews")
    first_high = create_review(book, 5, "First high")
    create_review(book, 5, "Second high")
    first_low = create_review(book, 1, "First low")
    create_review(book, 1, "Second low")

    row = TopRatedBooksQuery.new.call.find { |candidate| candidate.id == book.id }

    assert_equal first_high.review_text, row.highest_rated_review
    assert_equal first_high.score, row.highest_review_score
    assert_equal first_low.review_text, row.lowest_rated_review
    assert_equal first_low.score, row.lowest_review_score
    assert_equal BigDecimal("3"), row.average_score
  end

  test "returns at most ten books with deterministic tie ordering" do
    author = create_author
    books = 11.times.map do |index|
      book = create_book(author, format("Book %02d", 10 - index))
      create_review(book, 4, "Same score")
      book
    end

    expected_ids = books.sort_by { |book| [ book.name.downcase, book.id ] }.first(10).map(&:id)

    assert_equal expected_ids, TopRatedBooksQuery.new.call.map(&:id)
  end

  test "uses book id as the final ranking tie breaker for identical names" do
    author = create_author
    first = create_book(author, "Identical Name")
    second = create_book(author, "Identical Name")
    create_review(first, 4, "First book review")
    create_review(second, 4, "Second book review")

    assert_equal [ first.id, second.id ], TopRatedBooksQuery.new.call.map(&:id)
  end

  private

  def create_author
    Author.create!(name: "Ratings Author")
  end

  def create_book(author, name)
    Book.create!(author: author, name: name, summary: "Summary", date_of_publication: Date.new(2020, 1, 1))
  end

  def create_review(book, score, text)
    Review.create!(book: book, score: score, review_text: text, up_votes: 0)
  end
end
