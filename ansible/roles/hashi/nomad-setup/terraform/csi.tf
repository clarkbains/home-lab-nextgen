


locals {
  jobspec_base = "${path.module}/jobspecs"
  jobspec_auto_base = "${path.module}/jobspecs-auto"

  monitors = ["10.7.0.2", "10.7.0.3", "10.7.0.4"]
}

resource "nomad_variable" "csi_vars" {
  for_each = toset( [ 
    "nomad/jobs/cephfs-csi-plugin-controller",
    "nomad/jobs/ceph-csi-plugin-controller"
   ])
  path  = "${each.key}"
  items = {
    fsid = module.ceph-auth.fsid
    monitors = jsonencode(local.monitors)
  }
  namespace = "default"
}



module "ceph-auth" {
  source = "./modules/cephfs-key"
  remote_host = var.ceph_cli_host
  remote_user = var.ceph_cli_user
  remote_private_key = file(var.ceph_cli_key)
  monitors = local.monitors
}

resource "nomad_job" "iscsicontroller" {
  jobspec = file("${local.jobspec_base}/csi/truenas-iscsi/controller.nomad")
  purge_on_destroy = true
}


resource "nomad_job" "iscsinodes" {
  jobspec = file("${local.jobspec_base}/csi/truenas-iscsi/node.nomad")
  purge_on_destroy = true
}

resource "nomad_job" "controller" {
  depends_on = [ nomad_variable.csi_vars ]
  jobspec = file("${local.jobspec_base}/csi/cephfs/cephfs-csi-plugin-controller.hcl")
  purge_on_destroy = true

}

resource "nomad_job" "nodes" {
  depends_on = [ nomad_variable.csi_vars ]
  jobspec = file("${local.jobspec_base}/csi/cephfs/cephfs-csi-plugin-nodes.nomad")
  purge_on_destroy = true

}

resource "nomad_job" "rbdcontroller" {
  jobspec = file("${local.jobspec_base}/csi/rbd/ceph-csi-plugin-controller.hcl")
  purge_on_destroy = true

}

resource "nomad_job" "auto" {
  for_each = fileset(local.jobspec_auto_base, "**/*")

  jobspec = file("${local.jobspec_auto_base}/${each.key}")
  purge_on_destroy = true
}

resource "nomad_job" "rbdnodes" {
  depends_on = [ nomad_job.rbdcontroller ]
  jobspec = file("${local.jobspec_base}/csi/rbd/ceph-csi-plugin-nodes.nomad")
  purge_on_destroy = true

}

# resource "nomad_job" "nextcloud" {
#   depends_on = [ module.nextcloudData ]
#   jobspec = file("${local.jobspec_base}/services/nextcloud.nomad")
#   purge_on_destroy = true
# }

# resource "nomad_job" "owncloud" {
#   depends_on = [ module.nextcloudData ]
#   jobspec = file("${local.jobspec_base}/services/owncloud.nomad")
#   purge_on_destroy = true
# }


resource "nomad_job" "traefik" {
  depends_on = [ module.nextcloudData ]
  jobspec = replace(file("${local.jobspec_base}/infra/traefik.nomad"), "{{CONSUL}}", var.consul_token) 
  purge_on_destroy = true
}

resource "nomad_job" "nexus" {
  depends_on = [ module.nexusdata ]
  jobspec = file("${local.jobspec_base}/infra/nexus.nomad")
  purge_on_destroy = true
}

resource "nomad_job" "monitoring" {
  depends_on = [ module.prometheusdata ]
  jobspec = file("${local.jobspec_base}/infra/monitoring.nomad")
  purge_on_destroy = true
}

resource "nomad_job" "canal" {
  depends_on = [ module.canaldata ]
  jobspec = file("${local.jobspec_base}/services/canalbot.hcl")
  purge_on_destroy = true
}



resource "nomad_job" "demo-app" {
  jobspec = file("${local.jobspec_base}/services/demo-app.hcl")
  purge_on_destroy = true
}

resource "nomad_job" "mesh" {
  jobspec = file("${local.jobspec_base}/services/service-mesh.nomad")
  purge_on_destroy = true
}



# module "nomad-volume" {
#   source = "./modules/cephfs-volume"
#   ceph_creds = module.ceph-auth
#   name = "Waypoint Data"
#   max-size = "20GiB"
# }

module "nextcloudData" {
  depends_on = [ data.nomad_plugin.name ]
  source = "./modules/cephfs-volume"
  ceph_creds = module.ceph-auth
  name = "nextcloudprimary"
  access_mode = "multi-node-multi-writer"
  max-size = "1TiB"
}

module "nextcloudDb" {
  depends_on = [ data.nomad_plugin.name ]
  source = "./modules/ceph-rbd"
  ceph_creds = module.ceph-auth
  name = "nextclouddb"
  data_pool = "SP-GeoCloud"
  max-size = "25GiB"
  fs = "xfs"
}

module "traefikCerts" {
  depends_on = [ data.nomad_plugin.name ]
  source = "./modules/cephfs-volume"
  ceph_creds = module.ceph-auth
  name = "traefikcerts"
  #access_mode = "multi-node-multi-writer"
  max-size = "10MiB"
}

module "nexusdata" {
  depends_on = [ data.nomad_plugin.name ]
  source = "./modules/cephfs-volume"
  ceph_creds = module.ceph-auth
  name = "nexusdata"
  #access_mode = "multi-node-multi-writer"
  max-size = "100GiB"
}

module "prometheusdata" {
  depends_on = [ data.nomad_plugin.name ]
  source = "./modules/ceph-rbd2"
  ceph_creds = module.ceph-auth
  name = "prometheusdata"
  access_mode = "single-node-writer"

  #access_mode = "multi-node-multi-writer"
  max-size = "1GiB"
  data_pool = "SP-Local"
  fs = "xfs"

}

module "canaldata" {
  depends_on = [ data.nomad_plugin.name ]
  source = "./modules/ceph-rbd"
  ceph_creds = module.ceph-auth
  name = "canaldata"
  data_pool = "SP-Local"
  #access_mode = "multi-node-multi-writer"
  max-size = "1GiB"
}

data "nomad_plugin" "name" {
  depends_on = [ nomad_job.controller, nomad_job.nodes ]
  wait_for_healthy = true
  plugin_id = "cephfs-csi"
}



# resource "nomad_csi_volume_registration" "mysql_volume" {
#   external_id = nomad_csi_volume.mysql_volume.volume_id
#   plugin_id    = "cephfs-csi"
#   volume_id    = "nextclouddata"
#   name         = "Next Cloud Data"
#   capability {
#     access_mode     = "single-node-writer"
#     attachment_mode = "file-system"
#   }

#   mount_options {
#     fs_type = "ext4"
#     mount_flags = [ "noatime" ]
#   }

#   secrets = {
#     userID = module.nextcloud.client
#     userKey = module.nextcloud.token
#     adminID  = "admin"
#     adminKey = "AQCQVaBknisbBBAAbGirsSgYcX3SCOh5srWpQA=="
#   }

#   parameters = {
#     cluserId = module.nextcloud.fsid
#     fsName = module.nextcloud.pool
#   }

#   context = {
#       monitors = "10.7.0.2"
#       provisionVolume = "false"
#       rootPath = module.nextcloud.path
#       mounter = "fuse"
#   }

# }

