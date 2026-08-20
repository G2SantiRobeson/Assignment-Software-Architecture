require "test_helper"

class BookTest < ActiveSupport::TestCase
  setup do
    @author = Author.create!(name: "Toni Morrison")
  end

  test "requires an author, name, and publication date" do
    book = Book.new(number_of_sales: 0)

    assert_not book.valid?
    assert_includes book.errors[:author], "must exist"
    assert_includes book.errors[:name], "can't be blank"
    assert_includes book.errors[:date_of_publication], "can't be blank"
  end

  test "requires a nonnegative integer lifetime sales total" do
    book = build_book(number_of_sales: -1)

    assert_not book.valid?
    assert_includes book.errors[:number_of_sales], "must be greater than or equal to 0"

    book.number_of_sales = 1.5
    assert_not book.valid?
    assert_includes book.errors[:number_of_sales], "must be an integer"
  end

  test "normalizes blank Open Library keys to nil" do
    book = build_book(open_library_key: "  ")

    assert book.valid?
    assert_nil book.open_library_key
  end

  test "requires Open Library keys to be unique when present" do
    create_book(open_library_key: "/works/OL45804W")
    duplicate = build_book(name: "Duplicate", open_library_key: "/works/OL45804W")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:open_library_key], "has already been taken"
  end

  test "does not destroy a book that still has reviews" do
    book = create_book
    Review.create!(book: book, review_text: "Remarkable.", score: 5, up_votes: 2)

    assert_not book.destroy
    assert_predicate book, :persisted?
    assert_includes book.errors[:base], "Cannot delete record because dependent reviews exist"
  end

  test "does not destroy a book that still has sales" do
    book = create_book
    Sale.create!(book: book, year: 1987, sales: 100)

    assert_not book.destroy
    assert_predicate book, :persisted?
    assert_includes book.errors[:base], "Cannot delete record because dependent sales exist"
  end

  private

  def build_book(attributes = {})
    Book.new({
      author: @author,
      name: "Beloved",
      date_of_publication: Date.new(1987, 9, 16)
    }.merge(attributes))
  end

  def create_book(attributes = {})
    build_book(attributes).tap(&:save!)
  end
end
