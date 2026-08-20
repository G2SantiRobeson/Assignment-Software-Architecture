require "test_helper"

class AuthorTest < ActiveSupport::TestCase
  test "requires a name" do
    author = Author.new(name: "   ")

    assert_not author.valid?
    assert_includes author.errors[:name], "can't be blank"
  end

  test "normalizes blank Open Library keys to nil" do
    author = Author.create!(name: "Octavia Butler", open_library_key: "   ")

    assert_nil author.open_library_key
  end

  test "allows multiple authors without an Open Library key" do
    Author.create!(name: "Author One")

    assert Author.new(name: "Author Two").valid?
  end

  test "requires Open Library keys to be unique when present" do
    Author.create!(name: "Ursula Le Guin", open_library_key: "/authors/OL31353A")
    duplicate = Author.new(name: "Duplicate", open_library_key: "/authors/OL31353A")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:open_library_key], "has already been taken"
  end

  test "does not destroy an author that still has books" do
    author = create_author
    create_book(author: author)

    assert_not author.destroy
    assert_predicate author, :persisted?
    assert_includes author.errors[:base], "Cannot delete record because dependent books exist"
  end

  private

  def create_author
    Author.create!(name: "N. K. Jemisin")
  end

  def create_book(author:)
    Book.create!(
      author: author,
      name: "The Fifth Season",
      date_of_publication: Date.new(2015, 8, 4)
    )
  end
end
