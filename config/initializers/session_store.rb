# Shared session state even when the deployment has no Redis service.
options = {
  key: "_book_reviews_session", expire_after: 1.day,
  httponly: true, same_site: :lax,
  secure: ENV.fetch("SESSION_SECURE", "false") == "true"
}

case ENV.fetch("SESSION_STORE", "database")
when "redis"
  session_cache = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch("SESSION_REDIS_URL"), namespace: "book_reviews:sessions:#{Rails.env}",
    expires_in: 1.day, connect_timeout: 1, read_timeout: 1, write_timeout: 1,
    # Losing a session must not silently fall back to per-process memory.
    error_handler: ->(method:, returning:, exception:) { raise exception }
  )
  Rails.application.config.session_store :cache_store, **options, cache: session_cache
when "database"
  Rails.application.config.session_store :active_record_store, **options, secure_session_only: true
else
  raise "SESSION_STORE must be database or redis"
end
