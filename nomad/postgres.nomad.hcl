job "book-reviews-postgres" {
  datacenters = ["dc1"]
  type        = "service"

  group "database" {
    count = 1

    network {
      port "db" {
        static = 5432
        to     = 5432
      }
    }

    service {
      name     = "book-reviews-postgres"
      provider = "nomad"
      port     = "db"

      check {
        name     = "postgres-tcp"
        type     = "tcp"
        interval = "5s"
        timeout  = "2s"
      }
    }

    restart {
      attempts = 5
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

    task "postgres" {
      driver = "docker"

      config {
        image = "postgres:16-alpine"
        ports = ["db"]

        mount {
          type     = "volume"
          source   = "book_reviews_nomad_postgres_data"
          target   = "/var/lib/postgresql/data"
          readonly = false

          volume_options {
            no_copy = false
            labels = {
              "com.book-reviews.owner" = "nomad"
            }
          }
        }
      }

      env {
        POSTGRES_DB   = "book_reviews_production"
        POSTGRES_USER = "book_reviews"
      }

      template {
        destination = "secrets/postgres.env"
        env         = true
        change_mode = "restart"
        data        = <<-EOT
POSTGRES_PASSWORD={{ with nomadVar "nomad/jobs/book-reviews-postgres" }}{{ .postgres_password | toJSON }}{{ end }}
EOT
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
