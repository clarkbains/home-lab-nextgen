variable "consul_token" {
  sensitive = true
  description = "consul token"
}

variable "consul_http" {
  sensitive = true
  description = "consul address"
}

variable "consul_dc" {
  sensitive = false
  description = "consul address"
}
