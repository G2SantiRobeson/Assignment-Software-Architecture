class BooksController < ApplicationController
  before_action :set_book, only: %i[show edit update destroy]
  before_action :load_authors, only: %i[new create edit update]

  def index
    @books = Book.includes(:author).order(Arel.sql("LOWER(books.name) ASC"), :id)
  end

  def show
    @reviews = @book.reviews.order(score: :desc, id: :asc).to_a
    @sales = @book.sales.order(year: :asc).to_a
  end

  def new
    @book = Book.new
  end

  def create
    @book = Book.new(book_params)
    if @book.save
      redirect_to @book, notice: "Book was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @book.update(book_params)
      redirect_to @book, notice: "Book was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @book.destroy
      redirect_to books_path, notice: "Book was deleted.", status: :see_other
    else
      redirect_to @book, alert: @book.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_book
    @book = Book.includes(:author).find(params[:id])
  end

  def load_authors
    @authors = Author.order(Arel.sql("LOWER(name) ASC"), :id)
  end

  def book_params
    params.require(:book).permit(:name, :summary, :date_of_publication, :author_id)
  end
end
