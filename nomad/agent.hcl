# Development-only Nomad client configuration for Linux/WSL2.
# The directory must exist before the agent starts. See README_DELIVERY_2.md.
client {
  options = {
    "driver.allowlist" = "docker"
  }

  host_volume "book_reviews_postgres_data" {
    path      = "/opt/nomad/volumes/book-reviews-postgres"
    read_only = false
  }
}
