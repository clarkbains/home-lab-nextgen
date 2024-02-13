# Inspired from https://github.com/CarletonComputerScienceSociety/cloud-native/blob/main/nomad/traefik/traefik.hcl


job "Monitoring" {
  datacenters = ["dc1"]

  group "prometheus" {
    count = 1
    volume "prometheusdata" {
      type            = "csi"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      source          = "prometheusdata"
    }

    network {
      port "prom-mgmt" {
        to = 9090
      }
    }

    service {
      name = "prom-mgmt"
      port = "prom-mgmt"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.prom-mgmt.rule=Host(`prometheus.int.oc.cbains.ca`)",
        "traefik.http.routers.prom-mgmt.entrypoints=https",
        "traefik.http.routers.prom-mgmt.tls.certresolver=letsencrypt",
      ]
      check {
        type     = "http"
        path     = "/"
        interval = "3s"
        timeout  = "2s"
      }
    }
    task "setup" {
      lifecycle {
        hook = "prestart"
      }
      driver = "docker"
      config {
        image = "docker.cbains.ca/alpine:latest"
        command = "chown"
        args = ["300:300", "/data"]
      } 
      volume_mount {
        volume      = "prometheusdata"
        destination = "/data"
      }
      resources {
        cpu    = 10
        memory = 10
      }
    }

    task "prometheus" {
      env {

      }
      driver = "docker"
      config {
        image = "docker.cbains.ca/prom/prometheus:latest"
        ports = ["prom-mgmt"]
      }

      volume_mount {
        volume      = "prometheusdata"
        destination = "/prometheus"
      }

      resources {
        cpu    = 1000
        memory = 400
      }
    }
  }
}
