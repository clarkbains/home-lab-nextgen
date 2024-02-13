job "canal-auto" {
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
      source          = "csi-volume-iscsi"
    }

    service {
      name = "canal"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.${NOMAD_JOB_NAME}.rule=Host(`canal2.ufd.oc.cbains.ca`)",
        "traefik.http.routers.${NOMAD_JOB_NAME}.entrypoints=https,https-pub",
        "traefik.http.routers.${NOMAD_JOB_NAME}.tls.certresolver=letsencrypt",
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
        memory = 400
      }
    }

  }
}
