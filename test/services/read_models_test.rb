require "test_helper"

class ReadModelsTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  class FailingStore
    def method_missing(*)
      raise Redis::CannotConnectError, "intentional test outage"
    end

    def respond_to_missing?(*)
      true
    end
  end

  setup do
    @old_cache = ENV["CACHE_ENABLED"]
    @old_search = ENV["SEARCH_ENABLED"]
    ENV["CACHE_ENABLED"] = "true"
    ENV["SEARCH_ENABLED"] = "false"
    @store = ActiveSupport::Cache::MemoryStore.new
    ReadCache.store = @store
    @authors = [ create_author, create_author, create_author ]
    @books = @authors.map { |author| create_book(author: author) }
  end

  teardown do
    ReadCache.store = nil
    ENV["CACHE_ENABLED"] = @old_cache
    ENV["SEARCH_ENABLED"] = @old_search
    Review.where(book_id: @books.map(&:id)).delete_all
    Sale.where(book_id: @books.map(&:id)).delete_all
    Book.where(id: @books.map(&:id)).delete_all
    Author.where(id: @authors.map(&:id)).delete_all
  end

  test "average miss calculates DB value and subsequent hit skips aggregate" do
    Review.create!(book: @books.first, review_text: "First", score: 4)
    queries = []
    subscriber = ->(_name, _start, _finish, _id, payload) { queries << payload[:sql] }
    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      assert_equal 4, @books.first.average_score
      assert_equal 1, queries.count { |sql| sql.include?('AVG("reviews"."score")') }
      queries.clear
      assert_equal 4, @books.first.average_score
      assert_empty queries.grep(/AVG/)
    end
  end

  test "disabled and failed Redis both return DB results without losing writes" do
    ENV["CACHE_ENABLED"] = "false"
    ReadCache.store = FailingStore.new
    review = Review.create!(book: @books.first, review_text: "First", score: 2)
    assert_equal 2, @books.first.average_score
    ENV["CACHE_ENABLED"] = "true"
    review.update!(score: 5)
    assert_equal 5, @books.first.average_score
    assert_equal 5, Review.find(review.id).score
    assert_equal 3, AuthorStatisticsQuery.new.call.where(id: @authors.map(&:id)).count(:all)
  end

  test "review create update destroy explicitly delete average rated and author entries" do
    keys = review_keys(@books.first)
    assert_invalidated(keys) { @review = Review.create!(book: @books.first, review_text: "First", score: 2) }
    assert_invalidated(keys) { @review.update!(review_text: "Changed", score: 5) }
    assert_invalidated(keys) { @review.destroy! }
    assert_equal 0, @books.first.average_score
  end

  test "sale create update destroy invalidate selling and author entries and preserve totals" do
    keys = [ CacheKeys::TOP_SELLING, CacheKeys.author(@authors.first.id) ]
    assert_invalidated(keys) { @sale = Sale.create!(book: @books.first, year: 2000, sales: 10) }
    assert_invalidated(keys) { @sale.update!(sales: 40) }
    assert_equal 40, @books.first.reload.number_of_sales
    assert_invalidated(keys) { @sale.destroy! }
    assert_equal 0, @books.first.reload.number_of_sales
  end

  test "relationship moves invalidate old and new dependencies including multiple saves" do
    review = Review.create!(book: @books.first, review_text: "Moving", score: 4)
    assert_invalidated(@books.flat_map { |book| review_keys(book) }.uniq) do
      Review.transaction do
        review.update!(book: @books.second)
        review.update!(book: @books.third)
        review.update!(up_votes: 2)
      end
    end
    sale = Sale.create!(book: @books.first, year: 2000, sales: 30)
    assert_invalidated([ CacheKeys::TOP_SELLING, *@authors.first(2).map { |author| CacheKeys.author(author.id) } ]) do
      sale.update!(book: @books.second)
    end
    assert_equal [ 0, 30 ], @books.first(2).map { |book| book.reload.number_of_sales }
    assert_invalidated(@authors.first(2).map { |author| CacheKeys.author(author.id) }) do
      @books.first.update!(author: @authors.second)
    end
  end

  test "book and author edits invalidate overview and display current names" do
    assert_invalidated([ CacheKeys.author(@authors.first.id) ]) { @books.first.update!(name: "Renamed") }
    CachedRankings.selling
    assert_invalidated([ CacheKeys.author(@authors.first.id) ]) { @authors.first.update!(name: "Current author") }
    row = CachedRankings.selling.find { |book| book.id == @books.first.id }
    assert_equal "Current author", row.author_name
    assert_equal "Renamed", row.name
  end

  test "rankings and author filters retain original query semantics on cold and warm cache" do
    @books.each_with_index do |book, index|
      Review.create!(book: book, score: index + 2, review_text: "Review #{index}")
      Sale.create!(book: book, year: book.date_of_publication.year, sales: (index + 1) * 10)
    end
    2.times do
      assert_equal TopRatedBooksQuery.new.call.map(&:attributes), CachedRankings.rated.map(&:attributes)
      assert_equal TopSellingBooksQuery.new.call.map(&:attributes), CachedRankings.selling.map(&:attributes)
      %w[author published_books average_score total_sales].product(%w[asc desc]).each do |sort, direction|
        params = { sort: sort, direction: direction, average_score_min: "2", total_sales_max: "25" }
        expected = AuthorStatisticsQuery.new(params, cache: false).call.map(&:attributes)
        assert_equal expected, AuthorStatisticsQuery.new(params).call.map(&:attributes)
      end
    end
  end

  test "rollback leaves cached results and revisions intact and transaction reads bypass cache" do
    book = @books.first
    Review.create!(book: book, score: 2, review_text: "Original")
    assert_equal 2, book.average_score
    versions = CacheRevision.versions(review_keys(book))
    Review.transaction do
      Review.create!(book: book, score: 4, review_text: "Rolled back")
      assert_equal 3, book.average_score
      raise ActiveRecord::Rollback
    end
    assert_equal versions, CacheRevision.versions(review_keys(book))
    assert_equal 2, book.average_score
  end

  test "failed invalidation and writes while disabled cannot resurrect old cache" do
    review = Review.create!(book: @books.first, score: 2, review_text: "Original")
    assert_equal 2, @books.first.average_score
    ReadCache.store = FailingStore.new
    review.update!(score: 4)
    ReadCache.store = @store
    assert_equal 4, @books.first.average_score
    ENV["CACHE_ENABLED"] = "false"
    review.update!(score: 5)
    ENV["CACHE_ENABLED"] = "true"
    assert_equal 5, @books.first.average_score
  end

  test "a reader finishing after invalidation cannot fill the current cache revision" do
    key = CacheKeys.average(@books.first.id)
    assert_equal 2, ReadCache.fetch(key) { CacheRevision.invalidate!([ key ]); 2 }
    assert_equal 5, ReadCache.fetch(key) { 5 }
  end

  private

  def review_keys(book)
    [ CacheKeys.average(book.id), CacheKeys::TOP_RATED, CacheKeys.author(book.author_id) ]
  end

  def assert_invalidated(keys)
    versions = CacheRevision.versions(keys)
    versions.each { |key, version| @store.write(CacheKeys.versioned(key, version), { value: :sentinel }) }
    yield
    current = CacheRevision.versions(keys)
    versions.each do |key, version|
      assert_operator current.fetch(key), :>, version, key
      assert_nil @store.read(CacheKeys.versioned(key, version)), key
    end
  end
end
