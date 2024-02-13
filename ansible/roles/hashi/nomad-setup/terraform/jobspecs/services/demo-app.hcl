job "demo-webapp" {
  datacenters = ["dc1"]

  group "demo" {
    count = 10
    network {
      port  "http"{
        to = -1
      }
    }

    service {
      name = "demo-webapp"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.demo-router.rule=Host(`demo1.int.oc.cbains.ca`)",
        "traefik.http.routers.demo-router.entrypoints=https",
        "traefik.http.routers.demo-router.tls.certresolver=letsencrypt",
      ]
      check {
        type     = "http"
        path     = "/"
        interval = "3s"
        timeout  = "2s"
      }
    }

    task "server" {
      env {
        PORT    = "${NOMAD_PORT_http}"
        NODE_IP = "${NOMAD_IP_http}"
      }

      driver = "docker"

      config {
        image = "hashicorp/demo-webapp-lb-guide"
        ports = ["http"]
      }
      resources {
        cpu    = 20
        memory = 20
      }
    }

  }
}
