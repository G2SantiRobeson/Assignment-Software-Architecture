require "test_helper"

class BookSummarySearchQueryTest < ActiveSupport::TestCase
  test "matches any word case-insensitively and orders deterministically" do
    author = create_author
    systems = create_book(author, "Charlie", "Distributed SYSTEMS are resilient")
    intelligence = create_book(author, "bravo", "An introduction to INTELLIGENCE")
    artificial = create_book(author, "Alpha", "Artificial life")
    create_book(author, "Unmatched", "Botanical reference")

    page = search("artificial intelligence systems")

    assert_equal [ artificial, intelligence, systems ].map(&:id), page.records.map(&:id)
    assert_equal 3, page.total_count
  end

  test "escapes percent and underscore SQL wildcards independently" do
    author = create_author
    literal_percent = create_book(author, "Literal Percent", "A 100% safe example")
    create_book(author, "Percent Lookalike", "A 100X safe example")
    literal_underscore = create_book(author, "Literal Underscore", "A snake_case example")
    create_book(author, "Underscore Lookalike", "A snakeXcase example")

    assert_equal [ literal_percent.id ], search("%").records.map(&:id)
    assert_equal [ literal_underscore.id ], search("_").records.map(&:id)
  end

  test "does not execute SQL syntax supplied as a search token" do
    author = create_author
    create_book(author, "Normal", "An ordinary summary")

    payload = "x%'OR'1'='1"
    page = search(payload)

    assert_empty page.records
    assert_equal 0, page.total_count
    assert_equal 1, Book.count
  end

  test "paginates in SQL and preserves the normalized query in navigation params" do
    author = create_author
    25.times do |index|
      create_book(author, format("Book %02d", index), "A shared summary")
    end

    page = search("  shared  ", page: 2, per_page: 10)

    assert_equal 25, page.total_count
    assert_equal 3, page.total_pages
    assert_equal 2, page.current_page
    assert_equal 10, page.records.length
    assert_equal (10..19).map { |index| format("Book %02d", index) }, page.records.map(&:name)
    assert_equal 1, page.prev_page
    assert_equal 3, page.next_page
    assert_equal "shared", page.q
    assert_equal({ q: "shared", page: 3 }, page.params_for_page(page.next_page))
  end

  test "normalizes invalid pages, clamps pages past the end, and caps page size" do
    author = create_author
    3.times { |index| create_book(author, "Book #{index}", "Needle") }

    invalid = search("needle", page: "-4", per_page: "invalid")
    past_end = search("needle", page: 99, per_page: 2)
    capped = search("needle", page: 1, per_page: 10_000)

    assert_equal 1, invalid.current_page
    assert_equal BookSummarySearchQuery::DEFAULT_PER_PAGE, invalid.per_page
    assert_equal 2, past_end.current_page
    assert_equal [ "Book 2" ], past_end.records.map(&:name)
    assert_equal BookSummarySearchQuery::MAX_PER_PAGE, capped.per_page
  end

  test "bounds oversized input before constructing OR predicates" do
    author = create_author
    early_match = create_book(author, "Early Match", "Contains word0001")
    create_book(author, "Late Match", "Contains word2000")
    query = (1..2_000).map { |index| format("word%04d", index) }.join(" ")

    page = search(query)
    expected_query = query.first(BookSummarySearchQuery::MAX_QUERY_LENGTH)
      .split(/\s+/)
      .first(BookSummarySearchQuery::MAX_TOKENS)
      .join(" ")

    assert_equal expected_query, page.q
    assert_operator page.q.length, :<=, BookSummarySearchQuery::MAX_QUERY_LENGTH
    assert_equal BookSummarySearchQuery::MAX_TOKENS, page.q.split.length
    assert_not_includes page.q.split, "word0051"
    assert_equal [ early_match.id ], page.records.map(&:id)
    assert_equal({ q: page.q, page: 2 }, page.params_for_page(2))
  end

  test "returns a clean empty first page for blank input" do
    page = search(" \t\n ")

    assert_empty page.records
    assert_equal 0, page.total_count
    assert_equal 0, page.total_pages
    assert_equal 1, page.current_page
    assert_nil page.prev_page
    assert_nil page.next_page
  end

  test "preloads authors for rendered search rows" do
    author = create_author
    create_book(author, "Match", "Needle")

    book = search("needle").records.first

    assert_predicate book.association(:author), :loaded?
    assert_equal author, book.author
  end

  private

  def search(query, page: 1, per_page: 20)
    BookSummarySearchQuery.new(query: query, page: page, per_page: per_page).call
  end

  def create_author
    Author.create!(name: "Search Author")
  end

  def create_book(author, name, summary)
    Book.create!(
      author: author,
      name: name,
      summary: summary,
      date_of_publication: Date.new(2020, 1, 1)
    )
  end
end
