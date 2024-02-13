datacenter = "homelab"
data_dir = "/opt/consul"
encrypt = "{{ consul_key_b64.content | b64decode | trim }}"
verify_incoming = false
verify_outgoing = false
verify_server_hostname = false
retry_join = ["{{ hostvars[consul_leader_host]['ansible_host']  }}"]
advertise_addr = "{{ hostvars[inventory_hostname]['ansible_host'] }}"
bind_addr = "0.0.0.0"
domain = "consul"
#acl {  
#    enabled        = true  
#    default_policy = "deny"  
#    down_policy    = "extend-cache"
#    enable_token_persistence = true
#}
enable_script_checks = true
connect {
    enabled = true
}
ports {
  grpc = 8502
}