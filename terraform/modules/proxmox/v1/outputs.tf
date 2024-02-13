output "fqdn" {
  value = "${var.hostname}.ott.cbains.ca"
}

#Delays the output until
output "ip" {
  depends_on = [ module.thinProvision.hash ]
  value = "${var.ip != "" ? var.ip : proxmox_vm_qemu.instance.default_ipv4_address}"
}

output "hostname" {
  value = var.hostname
}

output "tags" {
  value = var.ansibleTags
}

output "extraVars" {
  value = jsonencode(var.ansibleVars)
}

output "diskConfig" {
  value = merge({
    "root" : {
      type: "${var.rootType}"
      storage: var.rootStore
      slot: var.rootSlot,
      size: var.rootSize,
    }
  },
  zipmap([for n in var.auxDisks: n.name], [for n in var.auxDisks: {
    type: n.type
    storage: n.storage
    size: n.size
    slot: n.slot
  }]))
}