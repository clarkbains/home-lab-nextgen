job "nextcloud" {
  datacenters = ["dc1"]
  group "cache" {
    network {
      mode = "bridge"
    }
    service {
      name = "nc-redis-svc"
      port = "6379"
      connect {
        sidecar_service {
        }
      }
    }
    ephemeral_disk {
      migrate = true
      size    = 500
    }
    task "redis" {
      driver = "docker"
      config {
        image   = "docker.cbains.ca/redis:latest"
        command = "--loglevel debug"
        volumes = [
          "alloc/data/:/data"
        ]
      }


      resources {
        cpu    = 200
        memory = 400
      }
    }


  }
  group "database" {
    network {
      mode = "bridge"
    }
    volume "ceph-db" {
      type            = "csi"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      source          = "nextclouddb"
    }

    service {
      name = "nc-mysql-svc"
      port = "3306"
      connect {
        sidecar_service {
        }
      }
    }
    task "mysql" {
      env {
        MARIADB_ROOT_PASSWORD = "rootpasswd"
        MARIADB_DATABASE      = "nextcloud"
        MARIADB_USER          = "user"
        MARIADB_PASSWORD      = "password"
        MARIADB_AUTO_UPGRADE  = "true"
      }

      driver = "docker"
      volume_mount {
        volume      = "ceph-db"
        destination = "/var/lib/mysql"
        #destination = "/void"
      }
      config {
        image = "docker.cbains.ca/mariadb:latest"
      }
      resources {
        cpu    = 200
        memory = 500
      }
    }
  }

  group "nextcloud" {
    network {
      mode = "bridge"
      port "http" {
        to = 80
      }
    }

    volume "ceph-webapp" {
      type            = "csi"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
      source          = "nextcloudprimary"
    }
    service {
      name = "nextcloud-mysql-up"
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "nc-mysql-svc"
              local_bind_port  = 3306
            }
            upstreams {
              destination_name = "nc-redis-svc"
              local_bind_port  = 6379
            }
          }
        }
      }


    }

    service {
      name = "nextcloud-http"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.nextcloud.rule=Host(`nc.ufd.oc.cbains.ca`)",
        "traefik.http.routers.nextcloud.entrypoints=https",
        "traefik.http.routers.nextcloud.tls.certresolver=letsencrypt",
      ]
    }

    task "nextcloud" {
      env {
        MYSQL_DATABASE            = "nextcloud"
        MYSQL_USER                = "user"
        MYSQL_PASSWORD            = "password"
        MYSQL_HOST                = "${NOMAD_UPSTREAM_ADDR_nc-mysql-svc}"
        NEXTCLOUD_INIT_HTACCESS   = "true"
        NEXTCLOUD_TRUSTED_DOMAINS = "nc.ufd.oc.cbains.ca"
        TRUSTED_PROXIES           = "10.9.0.0/16"
        APACHE_DISABLE_REWRITE_IP = "1"
        PHP_MEMORY_LIMIT          = "3G"
        PHP_UPLOAD_LIMIT          = "1G"
        REDIS_HOST                = "127.0.0.1"
      }

      driver = "docker"
      volume_mount {
        volume      = "ceph-webapp"
        destination = "/var/www/html"
        #destination = "/void"
      }

      config {
        image = "docker.cbains.ca/homelab/nextcloud:latest"
        ports = ["http"]
      }

      resources {
        cpu    = 2000
        memory = 8096
      }
    }
  }
}
