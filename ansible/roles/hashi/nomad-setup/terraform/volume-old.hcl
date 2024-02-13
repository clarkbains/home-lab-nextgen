#sudo ceph fs authorize cephfs client.waypoint /waypoint rw

id = "nextclouddata"
name = "Next Cloud Data"
type = "csi"
plugin_id = "cephfs-csi"
capacity_min = "20M"
capacity_max = "20GiB"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}

mount_options {
  fs_type = "ext4"
  mount_flags = ["noatime"]
}
secrets {
  adminID  = "admin"
  adminKey = "AQCQVaBknisbBBAAbGirsSgYcX3SCOh5srWpQA=="
  userID  = "nomad-nextcloud"
  userKey = "AQAzGqZlrbJnEBAAcEbpbLtmDMptw988L78LYQ=="
}

parameters {
  clusterID = "f745510e-9fe2-4547-9d2e-8a4757a72310"
  fsName = "proxmox-data"
}

context {
  monitors = "10.7.0.2"
  provisionVolume = "false"
  rootPath = "/nomad/nextcloud"
  mounter = "fuse"
}
