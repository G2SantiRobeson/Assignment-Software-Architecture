class CachedAuthorStatistics
  FIELDS = %w[published_books_count average_score total_sales].freeze

  def self.sources
    ids = Author.pluck(:id)
    if ids.empty?
      return [ Arel.sql(AuthorStatisticsQuery::BOOK_STATISTICS_SQL), Arel.sql(AuthorStatisticsQuery::REVIEW_STATISTICS_SQL), Arel.sql(AuthorStatisticsQuery::SALES_STATISTICS_SQL) ]
    end

    keys = ids.to_h { |id| [ CacheKeys.author(id), id ] }
    rows = ReadCache.fetch_multi(keys.keys) do |missing|
      AuthorStatisticsQuery.new({}, cache: false).call.where(id: missing.map { |key| keys.fetch(key) })
        .to_h { |author| [ CacheKeys.author(author.id), author.attributes.slice(*FIELDS) ] }
    end
    # Keep filtering, numeric precision, collation and deterministic ordering in
    # the original SQL query. Only its three expensive aggregate sources change.
    FIELDS.map do |field|
      values = Arel::Nodes::ValuesList.new(keys.map { |key, id| [ id, rows.fetch(key).fetch(field) ] })
      source = Arel::Nodes::TableAlias.new(Arel::Nodes::Grouping.new(values), Arel.sql("cached(author_id, value)"))
      table = Arel::Table.new("cached")
      Arel::SelectManager.new.from(source).project(table[:author_id], table[:value].as(field))
    end
  end
end
