
# module "testProxmoxServer" {
#   source = "../modules/proxmox/v1"
#   memory = 2048
#   cpu = 2
#   hostname = "testTFNode2"
#   ip = "10.1.254.222"

#   auxDisks = [ {
#     type: "scsi",
#     storage: "local-rbd"
#     slot: 1,
#     size: 101,
#     name: "docker_data",
#   } ]
#   ansibleTags = [ "test" ]
#   ansibleVars = {
#     "diskfmt": {
#         "docker_data": "ext4"
#     },
#     "diskmnt": {
#         "docker_data": "/opt/mydata ext4 defaults,noatime 0 1"
#     }
#   }
# }

# module "testAveryServer" {
#     source = "../modules/proxmox/v1"
#     memory = 2000
#     cpu = 1
#     hostname = "avery"
#     ip = "10.1.254.221"
#     auxDisks = [ {
#         type: "scsi",
#         storage: "local-rbd"
#         slot: 1,
#         size: 50,
#         name: "docker_data",
#     } ]
# }
terraform {
  backend "s3" {
    bucket = "terraform-cbains"
    key    = "homelab/v1/instances"
    region = "ca-central-1"
  }
}

module "svc-cluster-server" {
    count = 3
    source = "../modules/proxmox/v1"
    memory = 2000
    cpu = 2
    hostname = "clust-serve-${count.index+1}"
    ip = "10.9.4.${count.index+1}"
    vlan = 9
    ansibleTags = [ "consul_server", "nomad_server", "vault_server", "debian" ]
}


locals {
  nomad_client_cfs = {
    "clust-client-1": {
      cpu = 4
      netid = 1
      memory = 8192+4096
      node = "proxmox2"
      dataSize = 512
      volumeNames = ["nextcloud", "nexus", "canal"]
    }
  }
}

module "svc-cluster-client" {
  for_each = local.nomad_client_cfs

    targetNode = "${each.value.node}"
    source = "../modules/proxmox/v1"
    memory = each.value.memory
    cpu = each.value.cpu
    hostname = each.key
    ip = "10.9.3.${each.value.netid}"
    vlan = 9
    auxDisks = [ {
        type: "scsi",
        storage: "local-rbd"
        slot: 1,
        size: 64,
        name: "docker_data",
        backup: false
    },
    {
        type: "scsi",
        storage: "local-rbd"
        slot: 2,
        size: each.value.dataSize,
        name: "nomad_data",
        backup: true

    } ]
    ansibleTags = [ "consul_client", "nomad_client", "debian" ]
    ansibleVars = {
        "diskfmt": {
            "docker_data": "ext4"
            "nomad_data": "ext4"
        },
        "diskmnt": {
            "docker_data": "/var/lib/docker ext4 defaults,noatime 0 1"
            "nomad_data": "/opt/nomad_data ext4 defaults,noatime 0 1"
        },
        "nomad_vols": {
            names = join(",", each.value.volumeNames)
        }
    }
}

module "ansibleHosts" {
  source = "../modules/ansiblehostsfile/v1"
  pm1 = concat(module.svc-cluster-server, values(module.svc-cluster-client))
  otherNodes1 = [{
    hostname: "proxmox"
    ip: "10.1.0.2",
    extraVars="remote_user=\"root\""
  }]
}

