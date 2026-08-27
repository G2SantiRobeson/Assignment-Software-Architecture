require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    author = Author.create!(name: "James Baldwin")
    @book = Book.create!(
      author: author,
      name: "Giovanni's Room",
      date_of_publication: Date.new(1956, 1, 1)
    )
  end

  test "requires a book and review text" do
    review = Review.new(review_text: " ", score: 3, up_votes: 0)

    assert_not review.valid?
    assert_includes review.errors[:book], "must exist"
    assert_includes review.errors[:review_text], "can't be blank"
  end

  test "requires an integer score from one through five" do
    [ nil, 0, 6, 2.5 ].each do |score|
      review = build_review(score: score)

      assert_not review.valid?, "expected score #{score.inspect} to be invalid"
    end

    (1..5).each do |score|
      assert build_review(score: score).valid?, "expected score #{score} to be valid"
    end
  end

  test "requires nonnegative integer up-votes" do
    assert_not build_review(up_votes: -1).valid?
    assert_not build_review(up_votes: 1.5).valid?
    assert build_review(up_votes: 0).valid?
  end

  private

  def build_review(attributes = {})
    Review.new({
      book: @book,
      review_text: "A precise and moving novel.",
      score: 5,
      up_votes: 0
    }.merge(attributes))
  end
end
