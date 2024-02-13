#Delays the output until
output "hash" {
  value = "${ansible_playbook.main.playbook_sha256_sum}"
}

output "stdout" {
  value = "${ansible_playbook.main.ansible_playbook_output}"
}

output "stderr" {
  value = "${ansible_playbook.main.ansible_playbook_err}"
}
