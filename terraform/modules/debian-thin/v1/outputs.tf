#Delays the output until
output "hash" {
  value = "${module.ansible.hash}"
}
