terraform {
  required_providers {

    nomad = {
      source  = "hashicorp/nomad"
      version = "2.1.0"
    }
  }
}

locals {
  sanitized_name = replace(var.name, "/[^a-zA-Z0-9]/", "")
}


resource "time_sleep" "wait_30_seconds" {
  create_duration  = "5s"
  destroy_duration = "5s"
}


resource "nomad_csi_volume" "data_volume" {
  depends_on = [time_sleep.wait_30_seconds]
  lifecycle {
    prevent_destroy = true
  }

  plugin_id    = "ceph-csi"
  volume_id    = local.sanitized_name
  name         = var.name
  capacity_min = var.max-size
  capacity_max = var.max-size
  
  capability {
    access_mode     = var.access_mode
    attachment_mode = "block-device"
    
  }

  mount_options {
    mount_flags = ["noatime"]
    fs_type = var.fs
  }

  secrets = {
    adminID  = var.ceph_creds.client
    adminKey = var.ceph_creds.token
    userID = var.ceph_creds.client
    userKey = var.ceph_creds.token
  }

  parameters = {
    pool             = var.data_pool
    clusterID        = var.ceph_creds.fsid
    tryOtherMounters = "true"
    imageFeatures = "layering"    
    volumeNamePrefix = "csi-${var.name}-"
        access_type = "block"

  }

  context = {
    monitors = "${join(",", var.ceph_creds.monitors)}"
    pool = var.data_pool
    access_type = "block"
  }
}
