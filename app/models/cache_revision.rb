# Transactional metadata, not cached business data. Bumping a version makes old
# Redis entries unreachable even if Redis was offline during invalidation.
class CacheRevision < ApplicationRecord
  self.primary_key = :key

  def self.versions(keys)
    # A request's SQL query cache must never hide a concurrent invalidation.
    keys.index_with(0).merge(uncached { where(key: keys).pluck(:key, :version).to_h })
  end

  def self.invalidate!(keys)
    previous = keys.compact.uniq.sort.to_h do |key|
      quoted = connection.quote(key)
      version = connection.select_value(<<~SQL).to_i
        INSERT INTO cache_revisions (key, version) VALUES (#{quoted}, 1)
        ON CONFLICT (key) DO UPDATE SET version = cache_revisions.version + 1
        RETURNING version
      SQL
      [ key, version - 1 ]
    end
    current_transaction.after_commit { ReadCache.delete_versions(previous) }
  end
end
