require "test_helper"

class AuthorStatisticsQueryTest < ActiveSupport::TestCase
  test "keeps empty authors and calculates independent aggregates without row multiplication" do
    empty_author = create_author("Empty Author")
    prolific_author = create_author("Prolific Author")
    first_book = create_book(prolific_author, "First")
    second_book = create_book(prolific_author, "Second")

    create_review(first_book, score: 5, text: "Excellent")
    create_review(first_book, score: 1, text: "Poor")
    create_review(second_book, score: 4, text: "Good")
    create_sale(first_book, year: 2020, sales: 100)
    create_sale(first_book, year: 2021, sales: 50)
    create_sale(second_book, year: 2020, sales: 25)

    rows = AuthorStatisticsQuery.new.call.index_by(&:id)

    assert_equal 0, rows.fetch(empty_author.id).published_books_count
    assert_equal BigDecimal("0"), rows.fetch(empty_author.id).average_score
    assert_equal 0, rows.fetch(empty_author.id).total_sales

    prolific_row = rows.fetch(prolific_author.id)
    assert_equal 2, prolific_row.published_books_count
    assert_in_delta BigDecimal("10") / 3, prolific_row.average_score, 0.00001
    assert_equal 175, prolific_row.total_sales
  end

  test "uses zero for missing review and sale aggregates without excluding authors with books" do
    no_reviews_author = create_author("No Reviews Author")
    no_sales_author = create_author("No Sales Author")
    reviewed_author = create_author("Reviewed and Sold Author")

    no_reviews_book = create_book(no_reviews_author, "No Reviews")
    no_sales_book = create_book(no_sales_author, "No Sales")
    reviewed_book = create_book(reviewed_author, "Reviewed and Sold")
    create_sale(no_reviews_book, year: 2020, sales: 25)
    create_review(no_sales_book, score: 4)
    create_review(reviewed_book, score: 2)
    create_sale(reviewed_book, year: 2020, sales: 10)

    rows = AuthorStatisticsQuery.new.call.index_by(&:id)

    assert_equal 1, rows.fetch(no_reviews_author.id).published_books_count
    assert_equal BigDecimal("0"), rows.fetch(no_reviews_author.id).average_score
    assert_equal 25, rows.fetch(no_reviews_author.id).total_sales
    assert_equal 1, rows.fetch(no_sales_author.id).published_books_count
    assert_equal BigDecimal("4"), rows.fetch(no_sales_author.id).average_score
    assert_equal 0, rows.fetch(no_sales_author.id).total_sales
  end

  test "sorts deterministically by every displayed statistic" do
    alpha = create_author("Alpha")
    beta = create_author("Beta")
    gamma = create_author("Gamma")

    alpha_book = create_book(alpha, "Alpha Book")
    beta_first = create_book(beta, "Beta One")
    beta_second = create_book(beta, "Beta Two")

    create_review(alpha_book, score: 2)
    create_review(beta_first, score: 5)
    create_review(beta_second, score: 3)
    create_sale(alpha_book, year: 2020, sales: 50)
    create_sale(beta_first, year: 2020, sales: 20)
    create_sale(beta_second, year: 2020, sales: 10)

    assert_equal [ gamma, beta, alpha ].map(&:id), ids_for(sort: "author", direction: "desc")
    assert_equal [ gamma, alpha, beta ].map(&:id), ids_for(sort: "published_books", direction: "asc")
    assert_equal [ beta, alpha, gamma ].map(&:id), ids_for(sort: "average_score", direction: "desc")
    assert_equal [ gamma, beta, alpha ].map(&:id), ids_for(sort: "total_sales", direction: "asc")
  end

  test "filters author and every numeric statistic" do
    matching = create_author("Target Writer")
    other = create_author("Other Writer")
    empty = create_author("Target Empty")

    matching_book = create_book(matching, "Matching One")
    create_book(matching, "Matching Two")
    other_book = create_book(other, "Other")
    create_review(matching_book, score: 4)
    create_review(other_book, score: 2)
    create_sale(matching_book, year: 2020, sales: 75)
    create_sale(other_book, year: 2020, sales: 10)

    result = AuthorStatisticsQuery.new(
      author: "target",
      published_books_min: "2",
      published_books_max: "2",
      average_score_min: "3.5",
      average_score_max: "4.5",
      total_sales_min: "70",
      total_sales_max: "80"
    ).call

    assert_equal [ matching.id ], result.pluck(:id)
    assert_not_includes result.pluck(:id), empty.id
  end

  test "applies every numeric minimum and maximum independently" do
    zero = create_author("Zero")
    low = create_author("Low")
    high = create_author("High")

    low_book = create_book(low, "Low Book")
    high_first = create_book(high, "High One")
    high_second = create_book(high, "High Two")
    create_review(low_book, score: 1)
    create_review(high_first, score: 5)
    create_review(high_second, score: 5)
    create_sale(low_book, year: 2020, sales: 10)
    create_sale(high_first, year: 2020, sales: 60)
    create_sale(high_second, year: 2020, sales: 40)

    assert_equal [ high.id ], filtered_ids(published_books_min: "2")
    assert_equal [ zero.id ], filtered_ids(published_books_max: "0")
    assert_equal [ high.id ], filtered_ids(average_score_min: "4")
    assert_equal [ zero.id, low.id ].sort, filtered_ids(average_score_max: "1")
    assert_equal [ high.id ], filtered_ids(total_sales_min: "50")
    assert_equal [ zero.id, low.id ].sort, filtered_ids(total_sales_max: "10")
  end

  test "treats percent and underscore author wildcards independently as literals" do
    literal_percent = create_author("The 100% Writer")
    create_author("The 100X Writer")
    literal_underscore = create_author("Under_score Writer")
    create_author("UnderXscore Writer")

    assert_equal [ literal_percent.id ], AuthorStatisticsQuery.new(author: "%").call.pluck(:id)
    assert_equal [ literal_underscore.id ], AuthorStatisticsQuery.new(author: "_").call.pluck(:id)
  end

  test "rejects arbitrary sort SQL and invalid numeric filters" do
    author = create_author("Safe Author")

    relation = AuthorStatisticsQuery.new(
      sort: "total_sales; DROP TABLE authors; --",
      direction: "desc NULLS FIRST; --",
      total_sales_min: "0) OR TRUE --"
    ).call

    assert_equal [ author.id ], relation.pluck(:id)
    assert_equal 1, Author.count
    assert_no_match(/DROP TABLE/i, relation.to_sql)
    assert_match(/LOWER\(authors\.name\) ASC/, relation.to_sql)
  end

  private

  def ids_for(params)
    AuthorStatisticsQuery.new(params).call.pluck(:id)
  end

  def filtered_ids(params)
    AuthorStatisticsQuery.new(params).call.pluck(:id).sort
  end

  def create_author(name)
    Author.create!(name: name)
  end

  def create_book(author, name)
    Book.create!(author: author, name: name, summary: "Summary", date_of_publication: Date.new(2020, 1, 1))
  end

  def create_review(book, score:, text: "Review")
    Review.create!(book: book, score: score, review_text: text, up_votes: 0)
  end

  def create_sale(book, year:, sales:)
    Sale.create!(book: book, year: year, sales: sales)
  end
end
