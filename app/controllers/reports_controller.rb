class ReportsController < ApplicationController
  def author_statistics
    @statistics = AuthorStatisticsQuery.new(params).call
  end

  def top_rated_books
    @books = TopRatedBooksQuery.new.call
  end

  def top_selling_books
    @books = TopSellingBooksQuery.new.call
  end
end
