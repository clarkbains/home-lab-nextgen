variable "consul_token" {
  sensitive = true
  description = "consul token"
  default = ""
}

variable "consul_http" {
  sensitive = true
  description = "consul address"
}

variable "consul_dc" {
  sensitive = false
  description = "consul address"
}


variable "nomad_token" {
  sensitive = true
  description = "nomad token"
}

variable "nomad_http" {
  sensitive = true
  description = "nomad address"
}

variable "ceph_cli_host" {
  type = string
}

variable "ceph_cli_user" {
  type = string
}

variable "ceph_cli_key" {
  type = string
}


# variable "nomad_dc" {
#   sensitive = false
#   description = "nomad address"
# }
