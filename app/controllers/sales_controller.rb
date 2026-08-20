class SalesController < ApplicationController
  before_action :set_sale, only: %i[show edit update destroy]
  before_action :load_books, only: %i[new create edit update]

  def index
    @sales = Sale.includes(book: :author).order(year: :desc, id: :desc)
  end

  def show; end

  def new
    @sale = Sale.new(book_id: params[:book_id])
  end

  def create
    @sale = Sale.new(sale_params)
    if @sale.save
      redirect_to @sale, notice: "Yearly sale was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @sale.update(sale_params)
      redirect_to @sale, notice: "Yearly sale was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sale.destroy!
    redirect_to sales_path, notice: "Yearly sale was deleted.", status: :see_other
  end

  private

  def set_sale
    @sale = Sale.includes(book: :author).find(params[:id])
  end

  def load_books
    @books = Book.includes(:author).order(Arel.sql("LOWER(books.name) ASC"), :id)
  end

  def sale_params
    params.require(:sale).permit(:book_id, :year, :sales)
  end
end
