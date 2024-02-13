# Inspired from https://github.com/CarletonComputerScienceSociety/cloud-native/blob/main/nomad/traefik/traefik.hcl


job "nexus" {
  datacenters = ["dc1"]

  group "nexus" {
    count = 1
    volume "nexus-data" {
      type            = "csi"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
      source          = "nexusdata"
    }

    network {
      port "mgmt" {
        to = 8081
      }
      port "hosted" {
        to = 7000
      }
      port "group" {
        to = 7001
      }
    }

    service {
      name = "nexus-mgmt"
      port = "mgmt"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.nexus-mgmt.rule=Host(`nexus.int.oc.cbains.ca`)",
        "traefik.http.routers.nexus-mgmt.entrypoints=https",
        "traefik.http.routers.nexus-mgmt.tls.certresolver=letsencrypt",
      ]
      check {
        type     = "http"
        path     = "/"
        interval = "3s"
        timeout  = "2s"
      }
    }
    service {
      name = "nexus-hosted"
      port = "hosted"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.nexus-hosted.rule=Host(`docker-hosted.cbains.ca`)",
        "traefik.http.routers.nexus-hosted.entrypoints=https",
        "traefik.http.routers.nexus-hosted.tls.certresolver=letsencrypt",
      ]
    }
    service {
      name = "nexus-group"
      port = "group"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.nexus-group.rule=Host(`docker.cbains.ca`)",
        "traefik.http.routers.nexus-group.entrypoints=https",
        "traefik.http.routers.nexus-group.tls.certresolver=letsencrypt",
      ]
    }

    task "nexus" {
      env {
        INSTALL4J_ADD_VM_PARAMS = "-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m  -XX:LogFile=/nexus-data/jvm.log"
      }
      driver = "docker"
      config {
        image = "sonatype/nexus3"
        ports = ["mgmt", "hosted", "group"]
      }

      volume_mount {
        volume      = "nexus-data"
        destination = "/nexus-data"
      }

      resources {
        cpu    = 1000
        memory = 4000
      }
    }
  }
}
