# Only the assignment's four derived results use this cache.
class ReadCache
  class << self
    attr_writer :store

    def enabled?
      ENV.fetch("CACHE_ENABLED", "false") == "true"
    end

    def store
      @store ||= ActiveSupport::Cache::RedisCacheStore.new(
        url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
        namespace: "book_reviews:#{Rails.env}", expires_in: 1.hour,
        connect_timeout: 0.3, read_timeout: 0.3, write_timeout: 0.3,
        reconnect_attempts: 0,
        error_handler: ->(method:, returning:, exception:) {
          Rails.logger.warn("Redis #{method} failed (#{exception.class}); using PostgreSQL")
        }
      )
    end

    def fetch(key)
      return yield unless enabled? && !ApplicationRecord.connection.transaction_open?

      physical_key = CacheKeys.versioned(key, CacheRevision.versions([ key ]).fetch(key))
      cached = safely { store.read(physical_key) }
      return cached.fetch(:value) if cached

      value = yield
      safely { store.write(physical_key, { value: value }) }
      value
    end

    # The loader receives only misses and calculates them with one aggregate query.
    def fetch_multi(keys)
      return yield(keys) unless enabled? && !ApplicationRecord.connection.transaction_open?

      versions = CacheRevision.versions(keys)
      physical = keys.to_h { |key| [ key, CacheKeys.versioned(key, versions.fetch(key)) ] }
      cached = safely { store.read_multi(*physical.values) } || {}
      missing = keys.reject { |key| cached.key?(physical.fetch(key)) }
      loaded = missing.empty? ? {} : yield(missing)
      writes = loaded.to_h { |key, value| [ physical.fetch(key), { value: value } ] }
      safely { store.write_multi(writes) } if writes.any?
      keys.to_h { |key| [ key, cached[physical[key]] ? cached[physical[key]][:value] : loaded.fetch(key) ] }
    end

    def delete_versions(versions)
      return unless enabled?

      versions.each { |key, version| safely { store.delete(CacheKeys.versioned(key, version)) } }
    end

    private

    def safely
      yield
    rescue Redis::BaseError, ConnectionPool::TimeoutError, IOError, SystemCallError => error
      Rails.logger.warn("Redis unavailable (#{error.class}); using PostgreSQL")
      nil
    end
  end
end
