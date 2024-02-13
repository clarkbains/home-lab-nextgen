job "countdash" {
  datacenters = ["dc1"]
  group "api" {
    network {
      mode = "bridge"
      port "count_api_port" {}
    }

    service {
      name = "count-api"
      port = "count_api_port"

      connect {
        sidecar_service {
        }
      }
    }

    task "web" {
      env {
        PORT = "${NOMAD_PORT_count_api_port}"
      }
      driver = "docker"
      config {
        image = "hashicorpnomad/counter-api:v1"
      }
    }
  }

  group "dashboard" {
    network {
      mode = "bridge"
      port "http" {
        //static = 9002
        to     = 9002
      }
    }

    service {
      name = "count-dashboard"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.connectrouter.rule=Host(`cert.ufd.oc.cbains.ca`)",
        "traefik.http.routers.connectrouter.entrypoints=https",
        "traefik.http.routers.connectrouter.tls.certresolver=letsencrypt",
      ]
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "count-api"
              local_bind_port  = 8080
            }
          }
          tags = [
            "traefik.enable=false"
          ]
        }
      }
    }

    task "dashboard" {
      driver = "docker"
      env {
        COUNTING_SERVICE_URL = "http://${NOMAD_UPSTREAM_ADDR_count_api}"
      }
      config {
        image = "hashicorpnomad/counter-dashboard:v1"
      }
    }
  }
}