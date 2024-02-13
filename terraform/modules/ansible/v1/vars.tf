variable "playbook" {
  type = string
}

variable "host" {
  type = string
}

variable "roles_directories" {
  type = list(string)
  default = [
    "../../ansible/roles"
  ]
}

variable "tags" {
  type = list(string)
  default = [  ]
}

variable "extra_vars" {
  type = map(string)
  default = {}
}

variable "replayable" {
  type = bool
  default = true
}



