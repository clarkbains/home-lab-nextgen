# Inspired from https://github.com/CarletonComputerScienceSociety/cloud-native/blob/main/nomad/traefik/traefik.hcl


job "traefik" {
  region      = "global"
  datacenters = ["dc1"]
  #Ingress traffic is on this node
  constraint {
    attribute = "${node.unique.name}"
    value     = "clust-client-1"
  }
  group "traefik" {
    count = 1

    volume "certs" {
      type            = "csi"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      source          = "traefikcerts"
    }

    network {
      port "https" {
        static = 4443
      }

      port "https-pub" {
        static = 443
      }

      port "http" {
        static = 80
      }

    }

    service {
      name = "traefik"
      port = "https"
    }

    task "traefik" {
      driver = "docker"
      config {
        image        = "traefik:latest"
        network_mode = "host"
        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
          "local/dynamic/:/etc/traefik/config/dynamic/"
        ]
      }
      # vault {        
      #   policies = ["traefik"]
      # }



      volume_mount {
        volume      = "certs"
        destination = "/data"
      }

      template {
        data = <<EOF
# Allow backends to use self signed ssl certs (Needed for waypoint)
[log]
level = "debug"
[serversTransport]
  insecureSkipVerify = true
[entryPoints]
    [entryPoints.http]
    address = ":80"
    [entryPoints.https-pub]
    address = ":443"
    [entryPoints.https]
    address = ":4443"

[api]
    dashboard = true
    insecure = true

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    prefix           = "traefik"
    exposedByDefault = false
    [providers.consulCatalog.endpoint]
      address = "127.0.0.1:8500"
      scheme  = "http"
      token = "{{CONSUL}}"
[providers.consul]
    rootKey = "traefik"
    endpoints = ["127.0.0.1:8500"]
    token = "{{CONSUL}}"
[providers.file]
    directory = "/etc/traefik/config/dynamic"
    watch = true
[certificatesresolvers.letsencrypt.acme]
  email = "clarkbains@gmail.com"
  storage = "/data/acme.json"
  [certificatesresolvers.letsencrypt.acme.httpchallenge]
    entrypoint = "http"

EOF

        destination = "local/traefik.toml"
        change_mode = "restart"
      }
      template {
        data = <<EOF
[http]
  [http.routers]
    [http.routers.redirecttohttps]
      entryPoints = ["http"]
      middlewares = ["httpsredirect"]
      rule = "HostRegexp(`{host:.+}`)"
      service = "noop@internal"

  [http.middlewares]
    [http.middlewares.httpsredirect.redirectScheme]
      scheme = "https"
EOF
        destination = "local/dynamic/dynamic.toml"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
