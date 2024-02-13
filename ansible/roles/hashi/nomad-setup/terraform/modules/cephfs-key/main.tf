output "token" {
  value = data.external.example.result.token
}

output "fsid" {
  value = data.external.example.result.id
}

output "client" {
  value = data.external.example.result.client
}

output "monitors" {
  value =  var.monitors
}


# resource "null_resource" "cluster" {
#   triggers = {
#         user = var.remote_user
#         host = var.remote_host
#         private_key = base64encode(var.remote_private_key)
#         client_name = var.client_name
#         client_path = var.client_path
#         pool = var.data_pool
#   }

#   provisioner "local-exec" {
#     when = create
#     command = "./create-resource.sh"
#     working_dir = path.module
#     environment = {
#         user = var.remote_user
#         host = var.remote_host
#         private_key = base64encode(var.remote_private_key)
#         client_name = var.client_name
#         client_path = var.client_path
#         pool = var.data_pool
#     }
#   }
  
#   provisioner "local-exec" {
#     when = destroy
#     command = "./destroy-resource.sh"
#     working_dir = path.module
#     environment = {
#         user = self.triggers.user
#         host = self.triggers.host
#         private_key = self.triggers.private_key
#         client_name = self.triggers.client_name
#         client_path = self.triggers.client_path
#         pool = self.triggers.pool
#     }
#   }
# }


data "external" "example" {
  program = ["bash", "./get-resource.sh"]
  working_dir = path.module

  query = {
    user = var.remote_user
    host = var.remote_host
    private_key = base64encode(var.remote_private_key)
  }
}