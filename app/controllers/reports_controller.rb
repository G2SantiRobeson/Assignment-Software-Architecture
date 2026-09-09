class ReportsController < ApplicationController
  def author_statistics
    @statistics = AuthorStatisticsQuery.new(params).call
  end

  def top_rated_books
    @books = CachedRankings.rated
  end

  def top_selling_books
    @books = CachedRankings.selling
  end
end
