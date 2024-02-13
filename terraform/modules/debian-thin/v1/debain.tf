module "ansible" {
  source = "../../ansible/v1"
  playbook = "${path.module}/ansible/thin.yaml"
  host = var.host
  extra_vars = merge({
    "ansible_user": var.username,
    "thin_hostname": var.hostname,
    "ansible_ssh_extra_args": "-o StrictHostKeyChecking=no"
    "thin_provision_number": resource.random_id.num.hex
  }, (var.privateKeyPath == "" ? 
  {"ansible_ssh_pass": "${var.password}"} : 
  {"ansible_ssh_private_key_file": "${var.privateKeyPath}"}))
  replayable = true
}


check "loginCredential" {
  assert {
    condition = anytrue([var.privateKeyPath != "", var.password != ""])
    error_message = "One of PrivateKeyPath or Password must be set"
  }
}


resource "random_id" "num" {

  byte_length = 20
}