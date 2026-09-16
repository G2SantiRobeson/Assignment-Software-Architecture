class BookSearchesController < ApplicationController
  def index
    service = SearchService.new(query: params[:q], page: params[:page])
    @results = service.call
    @search_backend = service.backend
    response.set_header("X-Search-Backend", @search_backend.to_s)
    @query = @results.query
  end
end
