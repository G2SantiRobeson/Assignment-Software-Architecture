require "test_helper"

class ReportPagesTest < ActionDispatch::IntegrationTest
  setup do
    @author = create_author(name: "Report Author")
    @book = create_book(author: @author, name: "Report Book", summary: "Artificial systems and practical architecture")
    Review.create!(book: @book, review_text: "Strong", score: 5, up_votes: 2)
    Review.create!(book: @book, review_text: "Mixed", score: 3, up_votes: 1)
    Sale.create!(book: @book, year: @book.date_of_publication.year, sales: 100)
  end

  test "author statistics page renders filters and correct aggregate" do
    get author_statistics_path
    assert_response :success
    assert_select "a", text: "Report Author"
    assert_select "input[name='published_books_min']"
    assert_includes response.body, "100"
  end

  test "author statistics sort link reflects defaults and preserves filters" do
    get author_statistics_path, params: { author: "Report" }
    assert_response :success
    assert_select "a.active-sort[href*='sort=author'][href*='direction=desc'][href*='author=Report']", text: /Author.*▲/
  end

  test "top rated page renders selected reviews" do
    get top_rated_books_path
    assert_response :success
    assert_includes response.body, "Report Book"
    assert_includes response.body, "Strong"
    assert_includes response.body, "Mixed"
  end

  test "top selling page renders totals and publication year flag" do
    get top_selling_books_path
    assert_response :success
    assert_includes response.body, "Report Book"
    assert_includes response.body, "100"
    assert_select ".yes", text: "Yes"
  end

  test "search page handles blank, matches case-insensitively, and uses OR semantics" do
    get book_search_path
    assert_response :success
    assert_includes response.body, "Enter one or more words"

    get book_search_path, params: { q: "missing ARTIFICIAL" }
    assert_response :success
    assert_includes response.body, "Report Book"
    assert_select "input[name='q'][value='missing ARTIFICIAL']"
  end

  test "rendered search pagination preserves the query" do
    21.times do |index|
      create_book(author: @author, name: format("Paged Book %02d", index), summary: "pagination needle")
    end

    get book_search_path, params: { q: "needle" }
    assert_response :success
    assert_select "a", text: "Next →" do |links|
      assert_includes links.first["href"], "q=needle"
      assert_includes links.first["href"], "page=2"
    end

    get book_search_path, params: { q: "needle", page: 2 }
    assert_response :success
    assert_select "input[name='q'][value='needle']"
    assert_select ".pagination", text: /Page 2 of 2/
  end

  test "search page renders the bounded normalized query for oversized input" do
    matching = create_book(author: @author, name: "Bounded Search Match", summary: "Contains word0001")
    query = (1..2_000).map { |index| format("word%04d", index) }.join(" ")
    expected_query = query.first(BookSummarySearchQuery::MAX_QUERY_LENGTH)
      .split(/\s+/)
      .first(BookSummarySearchQuery::MAX_TOKENS)
      .join(" ")

    get book_search_path, params: { q: query }

    assert_response :success
    assert_select "input[name='q']" do |inputs|
      assert_equal expected_query, inputs.first["value"]
    end
    assert_select "a", text: matching.name
  end
end
