job "book-reviews" {
  datacenters = ["dc1"]
  type        = "service"

  group "database" {
    count = 1

    network {
      port "db" {
        to = 5432
      }
    }

    volume "postgres_data" {
      type      = "host"
      source    = "book_reviews_postgres_data"
      read_only = false
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "10s"
      mode     = "delay"
    }

    task "postgres" {
      driver = "docker"

      config {
        image = "postgres:16-alpine"
        ports = ["db"]
      }

      env {
        POSTGRES_DB = "postgres"
        PGDATA      = "/var/lib/postgresql/data/pgdata"
      }

      template {
        destination = "secrets/postgres.env"
        env         = true
        change_mode = "restart"
        data        = <<-EOT
POSTGRES_USER={{ with nomadVar "nomad/jobs/book-reviews" }}{{ .DB_USERNAME }}{{ end }}
POSTGRES_PASSWORD={{ with nomadVar "nomad/jobs/book-reviews" }}{{ .DB_PASSWORD }}{{ end }}
EOT
      }

      volume_mount {
        volume      = "postgres_data"
        destination = "/var/lib/postgresql/data"
        read_only   = false
      }

      service {
        name     = "book-reviews-postgres"
        provider = "nomad"
        port     = "db"

        check {
          name     = "postgres-tcp"
          type     = "tcp"
          interval = "10s"
          timeout  = "3s"

          check_restart {
            limit = 3
            grace = "30s"
          }
        }
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }

  group "web" {
    count = 1

    network {
      port "http" {
        static = 3000
        to     = 80
      }
    }

    update {
      max_parallel     = 1
      min_healthy_time = "10s"
      healthy_deadline = "5m"
      auto_revert      = true
    }

    restart {
      attempts = 20
      interval = "10m"
      delay    = "10s"
      mode     = "delay"
    }

    task "rails" {
      driver = "docker"

      config {
        image       = "book-reviews:local"
        force_pull  = false
        ports       = ["http"]
        extra_hosts = ["host.docker.internal:host-gateway"]
      }

      env {
        RAILS_ENV            = "production"
        RAILS_LOG_TO_STDOUT  = "true"
        RAILS_FORCE_SSL      = "false"
        RAILS_ASSUME_SSL     = "false"
        RAILS_MAX_THREADS    = "5"
        OPEN_LIBRARY_ENABLED = "false"
        DB_HOST              = "host.docker.internal"
      }

      template {
        destination = "secrets/rails.env"
        env         = true
        change_mode = "restart"
        data        = <<-EOT
DB_USERNAME={{ with nomadVar "nomad/jobs/book-reviews" }}{{ .DB_USERNAME }}{{ end }}
DB_PASSWORD={{ with nomadVar "nomad/jobs/book-reviews" }}{{ .DB_PASSWORD }}{{ end }}
SECRET_KEY_BASE={{ with nomadVar "nomad/jobs/book-reviews" }}{{ .SECRET_KEY_BASE }}{{ end }}
{{ $allocID := env "NOMAD_ALLOC_ID" -}}
{{ range nomadService 1 $allocID "book-reviews-postgres" -}}
DB_PORT={{ .Port }}
{{ end -}}
EOT
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

          check_restart {
            limit = 3
            grace = "5m"
          }
        }
      }

      resources {
        cpu    = 750
        memory = 768
      }

      kill_timeout = "30s"
    }
  }
}
