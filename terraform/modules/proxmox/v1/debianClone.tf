resource "proxmox_vm_qemu" "instance" {
  depends_on = [ opnsense_dhcp_static_map.preset ]
  name = var.hostname
  target_node = var.targetNode
  clone = "ansible-base"
  agent = 1
  qemu_os = "l26"
  boot = "order=${var.rootType}${var.rootSlot}"
  full_clone = true
  scsihw = "virtio-scsi-single"
  cores   = var.cpu
  memory = var.memory
  //Root
  disk {
    type = var.rootType
    slot = var.rootSlot
    storage = var.rootStore
    size = "${var.rootSize}G"
  }

  
  dynamic "disk" {
    for_each = var.auxDisks
    content {
      type = disk.value["type"]
      slot = disk.value["slot"]
      size = "${disk.value["size"]}G"
      storage = disk.value["storage"]
      backup = disk.value["backup"]
  #    discard = "on"
    }
  }


  network {
    bridge = "vmbr10"
    firewall = false
    model = "virtio"
    mtu = 1500
    tag = var.vlan
    macaddr = resource.macaddress.nodePhys.address
  }
  
}

resource "opnsense_dhcp_static_map" "preset" {
  count = var.ip == "" ? 0 : 1
  interface = jsondecode(file("${path.module}/interfaces.json"))[var.vlan]
  mac = resource.macaddress.nodePhys.address
  ipaddr = var.ip
  hostname = var.hostname
}

resource "opnsense_dhcp_static_map" "dhcp" {
  count = var.ip == "" ? 1 : 0
  interface = jsondecode(file("${path.module}/interfaces.json"))[var.vlan]
  mac = resource.macaddress.nodePhys.address
  ipaddr = proxmox_vm_qemu.instance.default_ipv4_address
  hostname = var.hostname

}

resource "macaddress" "nodePhys" {
    // 1A:B1:AB
    prefix = [26, 177, 171]
}

module "thinProvision" {
  source = "../../debian-thin/v1"
  username = "ansible"
  hostname = var.hostname
  host = var.ip != "" ? var.ip : proxmox_vm_qemu.instance.default_ipv4_address
  privateKeyPath = "/home/cbains/.ssh/id_ansible_ed25519"
}

