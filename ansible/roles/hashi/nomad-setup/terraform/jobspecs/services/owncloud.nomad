job "owncloud" {
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
   # volume "ceph-db" {
    #  type            = "csi"
    #  attachment_mode = "file-system"
    #  access_mode     = "single-node-writer"
    #  source          = "ownclouddb"
    #}

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
        MARIADB_DATABASE      = "owncloud"
        MARIADB_USER          = "user"
        MARIADB_PASSWORD      = "password"
        MARIADB_AUTO_UPGRADE  = "true"
      }

      driver = "docker"
     # volume_mount {
       # volume      = "ceph-db"
       # destination = "/var/lib/mysql"
        #destination = "/void"
      #}
      config {
        image = "docker.cbains.ca/mariadb:latest"
      }
      resources {
        cpu    = 200
        memory = 500
      }
    }
  }

  group "owncloud" {
    network {
      mode = "bridge"
      port "http" {
        static = 8080
        to = 8080
      }
    }

 #   volume "ceph-webapp" {
  #    type            = "csi"
   #   attachment_mode = "file-system"
    #  access_mode     = "multi-node-multi-writer"
 #     source          = "owncloudprimary"
  #  }
  
    service {
      name = "owncloud-mysql-up"
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
      name = "owncloud-http"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.owncloud.rule=Host(`cloud.ufd.oc.cbains.ca`)",
        "traefik.http.routers.owncloud.entrypoints=https",
        "traefik.http.routers.owncloud.tls.certresolver=letsencrypt",
      ]
    }

    task "owncloud" {
      env {
        MYSQL_DATABASE            = "owncloud"
        MYSQL_USER                = "user"
        MYSQL_PASSWORD            = "password"
        MYSQL_HOST                = "${NOMAD_UPSTREAM_ADDR_nc-mysql-svc}"
        OWNCLOUD_INIT_HTACCESS   = "true"
        OWNCLOUD_TRUSTED_DOMAINS = "cloud.ufd.oc.cbains.ca"
        TRUSTED_PROXIES           = "10.9.0.0/16"
        APACHE_DISABLE_REWRITE_IP = "1"
        PHP_MEMORY_LIMIT          = "3G"
        PHP_UPLOAD_LIMIT          = "1G"
        REDIS_HOST                = "127.0.0.1"
      }

      driver = "docker"
#      volume_mount {
 #       volume      = "ceph-webapp"
  #      destination = "/var/www/html"
        #destination = "/void"
   #   }

      config {
        image = "docker.cbains.ca/owncloud/server:latest"
        ports = ["http"]
      }

      resources {
        cpu    = 2000
        memory = 8096
      }
    }
  }
}
