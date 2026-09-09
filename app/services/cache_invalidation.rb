module CacheInvalidation
  def self.record_changed(record)
    keys = case record
    when Review, Sale
      ids = ([ record.book_id ] + Array(record.saved_changes["book_id"])).compact.uniq
      authors = Book.where(id: ids).distinct.pluck(:author_id)
      derived = record.is_a?(Review) ? [ CacheKeys::TOP_RATED, *ids.map { |id| CacheKeys.average(id) } ] : [ CacheKeys::TOP_SELLING ]
      derived + authors.map { |id| CacheKeys.author(id) }
    when Book
      authors = ([ record.author_id ] + Array(record.saved_changes["author_id"])).compact.uniq
      # Names break ranking ties; publication year and author affect sales data.
      [ CacheKeys::TOP_RATED, CacheKeys::TOP_SELLING, CacheKeys.average(record.id), *authors.map { |id| CacheKeys.author(id) } ]
    when Author
      [ CacheKeys.author(record.id) ]
    else
      []
    end
    CacheRevision.invalidate!(keys)
  end

  def self.all!
    CacheRevision.invalidate!([ CacheKeys::TOP_RATED, CacheKeys::TOP_SELLING, *CacheRevision.pluck(:key) ])
  end
end
