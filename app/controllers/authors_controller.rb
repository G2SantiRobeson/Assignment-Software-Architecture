class AuthorsController < ApplicationController
  before_action :set_author, only: %i[show edit update destroy]

  def index
    @authors = Author.order(Arel.sql("LOWER(name) ASC"), :id)
  end

  def show
    @books = @author.books.order(:date_of_publication, :name, :id).to_a
  end

  def new
    @author = Author.new
  end

  def create
    @author = Author.new(author_params)
    if @author.save
      redirect_to @author, notice: "Author was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @author.update(author_params)
      redirect_to @author, notice: "Author was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @author.destroy
      redirect_to authors_path, notice: "Author was deleted.", status: :see_other
    else
      redirect_to @author, alert: @author.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_author
    @author = Author.find(params[:id])
  end

  def author_params
    params.require(:author).permit(:name, :date_of_birth, :country_of_origin, :short_description)
  end
end
