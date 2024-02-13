job "canal" {
  datacenters = ["dc1"]

  group "canal" {
    network {
      port "http" {
        to = 8943
      }
    }
    volume "ceph-db" {
      type            = "csi"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      source          = "canaldata"
    }

    service {
      name = "canal"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.canalbot.rule=Host(`canal.ufd.oc.cbains.ca`)",
        "traefik.http.routers.canalbot.entrypoints=https,https-pub",
        "traefik.http.routers.canalbot.tls.certresolver=letsencrypt",
      ]
    }

    task "server" {
      env {
        admin_password = "z5fAjYnkPRcTLnVonEMIjqiSyjqm36sxxfFhS09"
        web_host       = "https://canal.ufd.oc.cbains.ca/"
      }

      driver = "docker"
      volume_mount {
        volume      = "ceph-db"
        destination = "/app/data/"
        #destination = "/void"
      }
      config {
        image = "docker.cbains.ca/homelab/skatebot:latest"
        ports = ["http"]
      }
      resources {
        cpu    = 200
        memory = 500
      }
    }

  }
}
