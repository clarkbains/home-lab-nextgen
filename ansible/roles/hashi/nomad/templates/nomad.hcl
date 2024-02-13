# /etc/nomad.d/common.hcl

# data_dir tends to be environment specific.
data_dir = "/opt/nomad/data"


consul {
  #token = " (nomad_server_key_b64 if mode == "server" else nomad_client_key_b64).content | b64decode  | trim }}"
    # Enables automatically registering the services.
  auto_advertise = true

  # Enabling the server and client to bootstrap using Consul.
  server_auto_join = true
  client_auto_join = true
}

acl {
  enabled = true
}