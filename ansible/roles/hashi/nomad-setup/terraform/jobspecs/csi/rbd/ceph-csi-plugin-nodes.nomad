job "ceph-csi-plugin-nodes" {
  datacenters = ["dc1"]
  type        = "system"
  group "nodes" {
    network {
      port "metrics" {
        to = 8080
      }
    }
    
    restart {
      attempts = 3
      delay    = "1m"
      interval = "10m"
      mode     = "delay"
    }

    task "ceph-node" {
      template {
        data        = <<EOF
[{
    "clusterID": "f745510e-9fe2-4547-9d2e-8a4757a72310",
    "monitors": ["10.7.0.2","10.7.0.3","10.7.0.4"]
}]
EOF 
        destination = "local/config.json"
        change_mode = "restart"
      }
      driver = "docker"
      config {
        image = "quay.io/cephcsi/cephcsi:v3.10.1"
        volumes = [
          "local/config.json:/etc/ceph-csi-config/config.json",
          "/lib/modules:/lib/modules"
        ]
        mounts = [
          {
            type     = "tmpfs"
            target   = "/tmp/csi/keys"
            readonly = false
            tmpfs_options = {
              size = 1000000 # size in bytes
            }
          }
        ]
        args = [
          "--type=rbd",
          "--drivername=rbd.csi.ceph.com",
          "--nodeserver=true",
          "--clustername=nomad",
          "--endpoint=unix://csi/csi.sock",
          "--nodeid=${node.unique.name}-fs",
          "--v=5",        ]
        privileged = true
      }
      resources {
        cpu    = 50
        memory = 128
      }
      csi_plugin {
        id        = "ceph-csi"
        type      = "node"
        mount_dir = "/csi"
      }
    }
  }
}