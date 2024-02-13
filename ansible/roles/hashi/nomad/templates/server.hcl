# /etc/nomad.d/server.hcl

server {
  enabled          = true
  bootstrap_expect = {{ num_servers }}
  csi_volume_claim_gc_threshold = "3m"
}
