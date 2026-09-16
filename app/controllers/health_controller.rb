class HealthController < ActionController::API
  def ready
    ApplicationRecord.connection.select_value("SELECT 1")
    if ENV["SESSION_STORE"] == "redis"
      redis = Redis.new(url: ENV.fetch("SESSION_REDIS_URL"), timeout: 1)
      redis.ping
    end
    # Cache and search retain Assignment 3's PostgreSQL fallbacks.
    render json: { status: "ready", instance: ENV.fetch("HOSTNAME", "native") }
  rescue StandardError => error
    Rails.logger.warn("Readiness failed: #{error.class}")
    render json: { status: "unavailable" }, status: :service_unavailable
  ensure
    redis&.close
  end
end
