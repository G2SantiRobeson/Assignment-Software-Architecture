require "test_helper"

class SearchServiceTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  class RecordingClient
    attr_reader :documents, :queries
    attr_accessor :response, :fail

    def initialize
      @documents = {}
      @queries = []
    end

    def indices
      self
    end

    def exists?(**)
      true
    end

    def index(id:, body:, **)
      raise IOError, "intentional outage" if fail

      @documents[id] = body
    end

    def delete(id:, **)
      @documents.delete(id)
    end

    def delete_by_query(body:, **)
      @documents.delete_if { |_id, doc| doc[:book_id] == body[:query][:term][:book_id] }
    end

    def search(body:, **)
      raise IOError, "intentional outage" if fail

      @queries << body
      response
    end
  end

  setup do
    @old_search = ENV["SEARCH_ENABLED"]
    @old_cache = ENV["CACHE_ENABLED"]
    ENV["SEARCH_ENABLED"] = "true"
    ENV["CACHE_ENABLED"] = "false"
    @client = RecordingClient.new
    @original = Search::Connection.method(:client)
    client = @client
    Search::Connection.define_singleton_method(:client) { client }
    @author = create_author
    @books = [ create_book(author: @author, name: "Z titleonly", summary: "summaryonly"),
      create_book(author: @author, name: "A other", summary: "other") ]
  end

  teardown do
    Search::Connection.define_singleton_method(:client, @original)
    ENV["SEARCH_ENABLED"] = @old_search
    ENV["CACHE_ENABLED"] = @old_cache
    Review.where(book_id: @books.map(&:id)).delete_all
    Book.where(id: @books.map(&:id)).delete_all
    Author.where(id: @author.id).delete_all
  end

  test "book and review CRUD synchronize separate documents after commit" do
    book = @books.first
    assert_equal book.name, @client.documents.fetch("book:#{book.id}")[:title]
    book.update!(name: "Changed title", summary: "Changed summary")
    assert_equal "Changed summary", @client.documents.fetch("book:#{book.id}")[:summary]
    review = Review.create!(book: book, review_text: "Review token", score: 3)
    assert_equal "Review token", @client.documents.fetch("review:#{review.id}")[:review_text]
    review.update!(review_text: "Updated review", book: @books.second)
    assert_equal @books.second.id.to_s, @client.documents.fetch("review:#{review.id}")[:book_id]
    assert_equal "Updated review", @client.documents.fetch("review:#{review.id}")[:review_text]
    review.destroy!
    assert_nil @client.documents["review:#{review.id}"]
    # Simulate an orphan projection from an earlier failed review deletion.
    @client.documents["review:orphan"] = { book_id: book.id.to_s, review_text: "Orphan" }
    book.reload.destroy!
    assert_nil @client.documents["book:#{book.id}"]
    assert_nil @client.documents["review:orphan"]
  end

  test "rolled back creates updates deletes never reach OpenSearch" do
    before = @client.documents.deep_dup
    Book.transaction do
      @books.first.update!(summary: "Uncommitted")
      Review.create!(book: @books.first, review_text: "Uncommitted review", score: 4)
      @books.second.destroy!
      assert_equal before, @client.documents
      raise ActiveRecord::Rollback
    end
    assert_equal before, @client.documents
  end

  test "query collapses books searches all fields and preserves relevance and pagination" do
    ids = @books.map(&:id)
    @client.response = { "hits" => { "hits" => ids.map { |id| { "_source" => { "book_id" => id.to_s } } } },
      "aggregations" => { "unique_books" => { "value" => 5 } } }
    result = SearchService.new(query: "token", page: 2, per_page: 2).call
    assert_equal ids, result.records.map(&:id)
    assert result.records.all? { |record| record.is_a?(Book) }
    assert_equal 2, result.current_page
    assert_equal 3, result.total_pages
    assert_equal 5, result.total_count
    query = @client.queries.last
    assert_equal 2, query[:from]
    assert_equal({ field: "book_id" }, query[:collapse])
    assert_equal [ "title^2", "summary", "review_text" ], query[:query][:multi_match][:fields]
  end

  test "disabled unavailable and partial responses use summary-only fallback" do
    Review.create!(book: @books.second, review_text: "reviewonly", score: 3)
    [ :disabled, :unavailable, :partial ].each do |mode|
      ENV["SEARCH_ENABLED"] = mode == :disabled ? "false" : "true"
      @client.fail = mode == :unavailable
      @client.response = { "timed_out" => true }
      assert_equal [ @books.first.id ], SearchService.new(query: "summaryonly", page: 1).call.records.map(&:id)
      assert_empty SearchService.new(query: "titleonly reviewonly", page: 1).call.records
    end
  end

  test "index outage never rejects a committed database write" do
    @client.fail = true
    @books.first.update!(summary: "Committed during outage")
    assert_equal "Committed during outage", @books.first.reload.summary
    assert_equal [ @books.first.id ], SearchService.new(query: "outage", page: 1).call.records.map(&:id)
  end
end
