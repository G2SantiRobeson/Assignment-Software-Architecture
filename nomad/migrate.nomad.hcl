job "book-reviews-migrate" {
  datacenters = ["dc1"]
  type        = "batch"

  group "migration" {
    count = 1

    restart {
      attempts = 3
      interval = "10m"
      delay    = "5s"
      mode     = "fail"
    }

    task "rails-migrate" {
      driver = "docker"

      config {
        image      = "book-reviews:nomad"
        force_pull = false
        command    = "./bin/rails"
        args       = ["db:prepare"]
      }

      env {
        RAILS_ENV   = "production"
        DB_NAME     = "book_reviews_production"
        DB_USERNAME = "book_reviews"
      }

      template {
        destination = "secrets/rails.env"
        env         = true
        change_mode = "restart"
        data        = <<-EOT
DB_PASSWORD={{ with nomadVar "nomad/jobs/book-reviews-migrate" }}{{ .database_password | toJSON }}{{ end }}
SECRET_KEY_BASE={{ with nomadVar "nomad/jobs/book-reviews-migrate" }}{{ .secret_key_base | toJSON }}{{ end }}
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
