variable "host" {
  type = string
  description = "Hostname or IP to connect to"
}

variable "username" {
    type = string
    description = "Username to connect with"
}

variable "privateKeyPath" {
    type = string
    default = ""
    description = "Private key to connect using"
}

variable "password" {
    type = string
    default = ""
    description = "Password to connect with"
}

variable "hostname" {
  type = string
}
