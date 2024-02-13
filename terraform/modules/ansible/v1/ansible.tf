terraform {
  required_providers {
    ansible = {
      version = "~> 2.0.2"
      source  = "NefixEstrada/ansible"
    }
  }
}

# The ansible playbook module cannot properly detect dependency changes
# So instead we traverse the files and create a hash of them all, and feed that to the extra_vars so that we force replacement (and reapply) when the playbook changes
data "external" "ansible_hash" {
  program = ["${path.module}/findDeps.sh", "${var.playbook}"]
}


resource "ansible_playbook" "main" {
  playbook   = var.playbook
  roles_directories = var.roles_directories
  tags = var.tags
  extra_vars = jsonencode(merge({
    "ansible_ssh_private_key_file" = "../../../ssh/id_ansible_ed25519"
    "playbook_hash" = "${var.replayable ? "${data.external.ansible_hash.result["hash"]}${data.external.ansible_hash.result["changed"]}" : ""}"
  }, var.extra_vars))
  name       = var.host
  replayable = var.replayable
}
