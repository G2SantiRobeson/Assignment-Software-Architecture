require "test_helper"

class AuthorsCrudTest < ActionDispatch::IntegrationTest
  test "index and show" do
    author = create_author
    get authors_path
    assert_response :success
    assert_select "a", text: author.name

    get author_path(author)
    assert_response :success
    assert_select "h1", text: author.name
  end

  test "new, create, and invalid create" do
    get new_author_path
    assert_response :success

    assert_difference("Author.count") do
      post authors_path, params: { author: { name: "Created Author", date_of_birth: "1980-02-03", country_of_origin: "Chile", short_description: "Biography" } }
    end
    assert_redirected_to author_path(Author.order(:id).last)

    assert_no_difference("Author.count") do
      post authors_path, params: { author: { name: "" } }
    end
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "edit, update, invalid update, and destroy" do
    author = create_author
    get edit_author_path(author)
    assert_response :success

    patch author_path(author), params: { author: { name: "Updated Author" } }
    assert_redirected_to author_path(author)
    assert_equal "Updated Author", author.reload.name

    patch author_path(author), params: { author: { name: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
    assert_equal "Updated Author", author.reload.name

    assert_difference("Author.count", -1) { delete author_path(author) }
    assert_redirected_to authors_path
  end

  test "destroy is rejected while books exist" do
    author = create_author
    create_book(author: author)

    assert_no_difference([ "Author.count", "Book.count" ]) { delete author_path(author) }
    assert_redirected_to author_path(author)
    follow_redirect!
    assert_select ".flash.alert", /dependent books exist/
  end
end

class BooksCrudTest < ActionDispatch::IntegrationTest
  test "index and show" do
    book = create_book
    get books_path
    assert_response :success
    assert_select "a", text: book.name
    get book_path(book)
    assert_response :success
    assert_select "h1", text: book.name
  end

  test "new, create, and invalid create" do
    author = create_author
    get new_book_path
    assert_response :success
    assert_select "select[name='book[author_id]']"

    assert_difference("Book.count") do
      post books_path, params: { book: { name: "Created Book", summary: "Summary", date_of_publication: "2012-03-04", author_id: author.id, number_of_sales: 99_999 } }
    end
    created = Book.order(:id).last
    assert_redirected_to book_path(created)
    assert_equal 0, created.number_of_sales

    assert_no_difference("Book.count") do
      post books_path, params: { book: { name: "", date_of_publication: "", author_id: "" } }
    end
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "edit, update, invalid update, and destroy" do
    book = create_book
    get edit_book_path(book)
    assert_response :success
    patch book_path(book), params: { book: { name: "Updated Book" } }
    assert_redirected_to book_path(book)
    assert_equal "Updated Book", book.reload.name

    patch book_path(book), params: { book: { name: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
    assert_equal "Updated Book", book.reload.name

    assert_difference("Book.count", -1) { delete book_path(book) }
    assert_redirected_to books_path
  end

  test "destroy is rejected while reviews or sales exist" do
    reviewed = create_book
    sold = create_book
    Review.create!(book: reviewed, review_text: "Review", score: 4, up_votes: 0)
    Sale.create!(book: sold, year: 2000, sales: 10)

    assert_no_difference("Book.count") { delete book_path(reviewed) }
    assert_redirected_to book_path(reviewed)
    follow_redirect!
    assert_select ".flash.alert", /dependent reviews exist/

    assert_no_difference("Book.count") { delete book_path(sold) }
    assert_redirected_to book_path(sold)
    follow_redirect!
    assert_select ".flash.alert", /dependent sales exist/
  end
end

class ReviewsCrudTest < ActionDispatch::IntegrationTest
  test "index and show" do
    review = Review.create!(book: create_book, review_text: "Insightful review", score: 4, up_votes: 3)
    get reviews_path
    assert_response :success
    assert_includes response.body, "Insightful review"
    get review_path(review)
    assert_response :success
    assert_includes response.body, "Insightful review"
  end

  test "new, create, and invalid create" do
    book = create_book
    get new_review_path
    assert_response :success
    assert_select "select[name='review[book_id]']"

    assert_difference("Review.count") do
      post reviews_path, params: { review: { book_id: book.id, review_text: "Created review", score: 5, up_votes: 7 } }
    end
    assert_redirected_to review_path(Review.order(:id).last)

    assert_no_difference("Review.count") do
      post reviews_path, params: { review: { book_id: book.id, review_text: "", score: 6, up_votes: -1 } }
    end
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "edit, update, invalid update, and destroy" do
    review = Review.create!(book: create_book, review_text: "Original", score: 3, up_votes: 0)
    deleted_review_path = review_path(review)
    get edit_review_path(review)
    assert_response :success
    patch review_path(review), params: { review: { review_text: "Updated", score: 4, up_votes: 2 } }
    assert_redirected_to review_path(review)
    assert_equal [ "Updated", 4, 2 ], review.reload.values_at(:review_text, :score, :up_votes)

    patch review_path(review), params: { review: { score: 0 } }
    assert_response :unprocessable_entity
    assert_select ".errors"
    assert_equal 4, review.reload.score

    assert_difference("Review.count", -1) { delete review_path(review) }
    assert_redirected_to reviews_path

    get deleted_review_path
    assert_response :see_other
    assert_redirected_to reviews_path
    follow_redirect!
    assert_select ".flash.alert", text: "Review no longer exists."
  end
end

class SalesCrudTest < ActionDispatch::IntegrationTest
  test "index and show" do
    sale = Sale.create!(book: create_book, year: 2000, sales: 25)
    get sales_path
    assert_response :success
    assert_includes response.body, "25"
    get sale_path(sale)
    assert_response :success
    assert_includes response.body, "2000"
  end

  test "new, create, and invalid create" do
    book = create_book
    get new_sale_path
    assert_response :success
    assert_select "select[name='sale[book_id]']"

    assert_difference("Sale.count") do
      post sales_path, params: { sale: { book_id: book.id, year: 2000, sales: 125 } }
    end
    assert_redirected_to sale_path(Sale.order(:id).last)
    assert_equal 125, book.reload.number_of_sales

    assert_no_difference("Sale.count") do
      post sales_path, params: { sale: { book_id: book.id, year: 2001, sales: -1 } }
    end
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "edit, update, invalid update, and destroy" do
    sale = Sale.create!(book: create_book, year: 2000, sales: 10)
    get edit_sale_path(sale)
    assert_response :success
    patch sale_path(sale), params: { sale: { sales: 40 } }
    assert_redirected_to sale_path(sale)
    assert_equal 40, sale.reload.sales
    assert_equal 40, sale.book.reload.number_of_sales

    patch sale_path(sale), params: { sale: { sales: -1 } }
    assert_response :unprocessable_entity
    assert_select ".errors"
    assert_equal 40, sale.reload.sales

    assert_difference("Sale.count", -1) { delete sale_path(sale) }
    assert_redirected_to sales_path
    assert_equal 0, sale.book.reload.number_of_sales
  end
end

class MissingCrudRecordsTest < ActionDispatch::IntegrationTest
  test "missing records redirect to their corresponding collection" do
    {
      author_path(missing_id_for(Author)) => [ authors_path, "Author" ],
      book_path(missing_id_for(Book)) => [ books_path, "Book" ],
      review_path(missing_id_for(Review)) => [ reviews_path, "Review" ],
      sale_path(missing_id_for(Sale)) => [ sales_path, "Sale" ]
    }.each do |missing_path, (collection_path, model_name)|
      get missing_path

      assert_response :see_other
      assert_redirected_to collection_path
      follow_redirect!
      assert_response :success
      assert_select ".flash.alert", text: "#{model_name} no longer exists."
    end
  end

  private

  def missing_id_for(model)
    model.maximum(:id).to_i + 1
  end
end
