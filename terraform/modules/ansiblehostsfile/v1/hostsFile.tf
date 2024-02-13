

resource "local_file" "inventory" {
  content  = templatefile("${path.module}/hosts.tpl", {pm1: var.pm1, on1: var.otherNodes1})
  
    filename = "${path.module}/inventory.ini"
}