module ReportsHelper
  def statistics_sort_link(label, column)
    selected_sort = AuthorStatisticsQuery::SORT_EXPRESSIONS.key?(params[:sort].to_s) ? params[:sort].to_s : "author"
    selected_direction = AuthorStatisticsQuery::DIRECTIONS.include?(params[:direction].to_s.downcase) ? params[:direction].to_s.downcase : "asc"
    active = selected_sort == column
    next_direction = active && selected_direction == "asc" ? "desc" : "asc"
    indicator = active ? (selected_direction == "asc" ? " ▲" : " ▼") : ""
    preserved = request.query_parameters.merge(sort: column, direction: next_direction)
    link_to "#{label}#{indicator}", author_statistics_path(preserved), class: ("active-sort" if active)
  end
end
