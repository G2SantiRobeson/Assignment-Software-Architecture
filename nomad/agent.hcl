name       = "book-reviews-local"
datacenter = "dc1"
region     = "global"
data_dir   = "/opt/nomad/data"
bind_addr  = "0.0.0.0"

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
  servers = ["127.0.0.1:4647"]

  options = {
    "driver.allowlist" = "docker"
  }
}

plugin "docker" {
  config {
    allow_privileged = false

    volumes {
      enabled = true
    }
  }
}

ui {
  enabled = true
}
