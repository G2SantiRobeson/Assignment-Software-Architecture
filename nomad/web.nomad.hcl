job "book-reviews-web" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    # Increase this count to run more Rails allocations. The host port is
    # dynamic, so replicas do not collide on a single Nomad client.
    count = 1

    network {
      port "http" {
        to = 80
      }
    }

    service {
      name     = "book-reviews-web"
      provider = "nomad"
      port     = "http"

      check {
        name     = "rails-health"
        type     = "http"
        path     = "/up"
        interval = "10s"
        timeout  = "3s"
      }
    }

    restart {
      attempts = 3
      interval = "5m"
      delay    = "5s"
      mode     = "delay"
    }

    reschedule {
      attempts       = 0
      unlimited      = true
      delay          = "10s"
      delay_function = "constant"
    }

    task "rails" {
      driver = "docker"

      config {
        image      = "book-reviews:nomad"
        force_pull = false
        ports      = ["http"]
      }

      env {
        RAILS_ENV       = "production"
        DB_NAME         = "book_reviews_production"
        DB_USERNAME     = "book_reviews"
        RAILS_LOG_LEVEL = "info"
      }

      template {
        destination = "secrets/rails.env"
        env         = true
        change_mode = "restart"
        data        = <<-EOT
DB_PASSWORD={{ with nomadVar "nomad/jobs/book-reviews-web" }}{{ .database_password | toJSON }}{{ end }}
SECRET_KEY_BASE={{ with nomadVar "nomad/jobs/book-reviews-web" }}{{ .secret_key_base | toJSON }}{{ end }}
{{ range nomadService "book-reviews-postgres" }}
DB_HOST={{ .Address | toJSON }}
DB_PORT={{ .Port | toJSON }}
{{ end }}
EOT
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
