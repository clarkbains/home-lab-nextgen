variable "hostname" {
    type = string
}

variable "ansibleTags" {
  type = list(string)
  default = [ ]
  validation {
    condition = alltrue([
      for n in var.ansibleTags: alltrue([length(regexall("^\\w+$", n)) > 0])
    ])
    error_message = "tag should be lowercase, and may use underscores"
  }
}

variable "ansibleVars" {
  type = map(any)
  default = {}
}

variable "cpu" {
  type = number
  description = "CPU to allocate"
  default = 1
}

variable "memory" {
  type = number
  description = "Memory to allocate"
  default = 1024
}

variable "vlan" {
  type = number
  description = "VLAN to be assigned to"
  default = 1
}

variable "baseImage" {
  type = string
  default = "ansible-base"
}

variable "targetNode" {
  type = string
  default = "proxmox"
  validation {
    condition = var.targetNode != "proxmox-mini"
    error_message = "targetNode must not be proxmox-mini"
  }
}

variable "rootSize" {
  type = number
  description = "How many GB to make root disk"
  default = 30
}

variable "rootStore" {
  type = string
  default = "local-rbd"
}

variable "rootType" {
  type = string
  default = "scsi"
}

variable "rootSlot" {
  type = number
  default = 0
}

variable ip {
  type = string
  default = ""
}

variable "auxDisks" {
  type = list(map(any))
  default = [ ]
  validation {
    condition = alltrue([
      for n in var.auxDisks: alltrue([contains(keys(n), "storage"), contains(keys(n), "backup"), contains(keys(n), "size"), contains(keys(n), "name"), contains(keys(n), "slot"), contains(keys(n), "type")])
    ])
    error_message = "[{type, storage, size, name, slot, mountpoint, backup}]"
  }
  validation {
    condition = alltrue([
      for n in var.auxDisks: alltrue([length(regexall("^\\w+$", n.name)) > 0])
    ])
    error_message = "names should be lowercase, and may use underscores"
  }
}

