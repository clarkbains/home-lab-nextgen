variable "remote_user" {
  type = string
  description = "Remote user to connect as"
}

variable "remote_host" {
  type = string
  description = "Remote user to connect as"
}


variable "remote_private_key" {
    type = string
}

variable "monitors" {
    type = list(string)
}
# variable "client_name" {
#   type = string
# }

# variable "client_path" {
#   type = string
# }

# variable "data_pool" {
#   type = string
# }