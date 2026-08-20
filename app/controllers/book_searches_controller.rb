class BookSearchesController < ApplicationController
  def index
    @results = BookSummarySearchQuery.new(query: params[:q], page: params[:page]).call
    @query = @results.query
  end
end
