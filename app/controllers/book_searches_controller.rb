class BookSearchesController < ApplicationController
  def index
    service = SearchService.new(query: params[:q], page: params[:page])
    @results = service.call
    @search_backend = service.backend
    @query = @results.query
  end
end
