class ReviewsController < ApplicationController
  before_action :set_review, only: %i[show edit update destroy]
  before_action :load_books, only: %i[new create edit update]

  def index
    @reviews = Review.includes(book: :author).order(created_at: :desc, id: :desc)
  end

  def show; end

  def new
    @review = Review.new(book_id: params[:book_id])
  end

  def create
    @review = Review.new(review_params)
    if @review.save
      redirect_to @review, notice: "Review was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @review.update(review_params)
      redirect_to @review, notice: "Review was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy!
    redirect_to reviews_path, notice: "Review was deleted.", status: :see_other
  end

  private

  def set_review
    @review = Review.includes(book: :author).find(params[:id])
  end

  def load_books
    @books = Book.includes(:author).order(Arel.sql("LOWER(books.name) ASC"), :id)
  end

  def review_params
    params.require(:review).permit(:book_id, :review_text, :score, :up_votes)
  end
end
