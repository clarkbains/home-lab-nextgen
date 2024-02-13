terraform {
  required_providers {

    nomad = {
      source = "hashicorp/nomad"
      version = "2.1.0"
    }
  }
}

locals {
  sanitized_name = replace(var.name, "/[^a-zA-Z0-9]/", "")
}


resource "time_sleep" "wait_30_seconds" {
  create_duration = "5s"
  destroy_duration = "5s"
}


resource "nomad_csi_volume" "data_volume" {
  depends_on = [time_sleep.wait_30_seconds]
  lifecycle {
    prevent_destroy = false
  }

  plugin_id    = "cephfs-csi"
  volume_id    = local.sanitized_name
  name         = var.name
  capacity_min = var.max-size
  capacity_max = var.max-size

  capability {
    access_mode     = var.access_mode
    attachment_mode = "file-system"
  }

  mount_options {
    mount_flags = [ "noatime", "fsid=${var.ceph_creds.fsid}" ]
  }

  secrets = {
    adminID = var.ceph_creds.client
    adminKey = var.ceph_creds.token
  }

  parameters = {
    fsName = var.data_pool
    clusterID = var.ceph_creds.fsid
  }
  
}

resource "nomad_csi_volume_registration" "addCtx" {
  external_id = nomad_csi_volume.data_volume.external_id
  name = nomad_csi_volume.data_volume.name
  volume_id = nomad_csi_volume.data_volume.volume_id
  plugin_id = nomad_csi_volume.data_volume.plugin_id
    capability {
    access_mode     = var.access_mode
    attachment_mode = "file-system"
  }

  secrets = {
    adminID = var.ceph_creds.client
    adminKey = var.ceph_creds.token
  }

  context = {
      monitors = "${join(",",var.ceph_creds.monitors)}"
      provisionVolume = "false"
      rootPath = "nomad/${local.sanitized_name}"
      mounter = "kernel"
      pool = var.data_pool
  }
}