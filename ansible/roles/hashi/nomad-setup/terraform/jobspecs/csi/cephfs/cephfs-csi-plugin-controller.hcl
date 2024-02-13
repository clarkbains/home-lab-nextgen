job "cephfs-csi-plugin-controller" {
  datacenters = ["dc1"]
  group "controller" {
    restart {
      attempts = 3
      delay    = "1m"
      interval = "10m"
      mode     = "delay"
    } 

    task "ceph-controller" {
      template {
        data        = <<EOF
[{
    "clusterID": "{{ with nomadVar "nomad/jobs/cephfs-csi-plugin-controller" }}{{ .fsid.Value }}{{ end }}",
    "monitors": {{ with nomadVar "nomad/jobs/cephfs-csi-plugin-controller" }}{{ .monitors.Value  }}{{ end }}
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
          "--type=cephfs",
          "--controllerserver=true",
          "--drivername=cephfs.csi.ceph.com",
          "--endpoint=unix://csifs/csi.sock",
          "--nodeid=${node.unique.name}",
          "--v=5",
        ]
        privileged = true

      }
      resources {
        cpu    = 500
        memory = 512
      }

      csi_plugin {
        id        = "cephfs-csi"
        type      = "controller"
        mount_dir = "/csifs"
      }
    }
  }
}