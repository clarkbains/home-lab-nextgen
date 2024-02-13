variable "max-size" {
  type = string
}

variable "data_pool" {
  default = "proxmox-data"
}

variable "name" {
    type = string
}

variable "access_mode" {
  type = string
  default = "single-node-writer"
}

variable "ceph_creds" {
    type = any
}