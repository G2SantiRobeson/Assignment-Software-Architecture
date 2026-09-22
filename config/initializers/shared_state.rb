# Assignment 3's ReadCache remains independent and keeps its own fallback logic.
Rails.application.config.cache_store = if ENV.fetch("CACHE_ENABLED", "false") == "true"
  [ :redis_cache_store, { url: ENV.fetch("REDIS_URL"), namespace: "book_reviews:rails:#{Rails.env}" } ]
else
  :null_store
end
Rails.cache = ActiveSupport::Cache.lookup_store(*Rails.application.config.cache_store)

Rails.application.config.hosts << ENV["APP_HOST"] if ENV["APP_HOST"].present?
Rails.application.config.host_authorization = { exclude: ->(request) { %w[/up /ready].include?(request.path) } }
