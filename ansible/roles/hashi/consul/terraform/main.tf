output "agent_token" {
  value = data.consul_acl_token_secret_id.agent_token_secret.secret_id
  sensitive = true
}
output "dns_token" {
  value = data.consul_acl_token_secret_id.dns_token_secret.secret_id
  sensitive = true
}

output "nomad_server_token" {
  value = data.consul_acl_token_secret_id.server_token_secret.secret_id
  sensitive = true
}

output "nomad_client_token" {
  value = data.consul_acl_token_secret_id.client_token_secret.secret_id
  sensitive = true
}

output "anonymous_token" {
  value = data.consul_acl_token_secret_id.anonymous_token_secret.secret_id
  sensitive = true
}

resource "consul_acl_policy" "dns" {
    name = "dns"
    datacenters = [ var.consul_dc ]
    rules = <<-RULE
    node_prefix "" {
  policy = "read"
}
service_prefix "" {
  policy = "read"
}
# only needed if using prepared queries
query_prefix "" {
  policy = "read"
}

session "" {
  policy = "write"
}

agent_prefix "" {
  policy = "read"
}
RULE
}

resource "consul_acl_token" "dns_token" {
    policies = [consul_acl_policy.dns.name]
    description = "DNS Token"
    local = true
}

data "consul_acl_token_secret_id" "dns_token_secret" {
    accessor_id = consul_acl_token.dns_token.id
}


resource "consul_acl_policy" "agent" {
  name = "agent"
  datacenters = [var.consul_dc]
  rules = <<-RULE
    node "" {
        policy = "write"
    }

    node_prefix "" {
        policy = "read"
    }
    
    service_prefix "" {
        policy = "read"
    }

    # only needed if using prepared queries

    query_prefix "" {
        policy = "read"
    }
RULE
}


resource "consul_acl_token" "agent_token" {
    policies = [consul_acl_policy.agent.name]
    description = "Agent Token"
    local = true
}

data "consul_acl_token_secret_id" "agent_token_secret" {
    accessor_id = consul_acl_token.agent_token.id
}

resource "consul_acl_policy" "nomad_server" {
    name = "nomad-server"
    rules = <<-HERE
agent_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "write"
}

acl  = "write"
mesh = "write"


key_prefix "" {
  policy = "write"
}
HERE
  
}

resource "consul_acl_policy" "nomad_client" {
    name = "nomad-client"
    rules = <<-HERE
agent_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "write"
}
HERE
  
}

resource "consul_acl_token" "client_token" {
    policies = [consul_acl_policy.nomad_client.name]
    description = "Client Token"
    local = true
}

data "consul_acl_token_secret_id" "client_token_secret" {
    accessor_id = consul_acl_token.client_token.id
}


resource "consul_acl_token" "server_token" {
    policies = [consul_acl_policy.nomad_server.name]
    description = "Server Token"
    local = true
}

data "consul_acl_token_secret_id" "server_token_secret" {
    accessor_id = consul_acl_token.server_token.id
}

resource "consul_acl_policy" "anonymous" {
    name = "anon"
    rules = <<-HERE
service_prefix "" { policy = "read" }
node_prefix    "" { policy = "read" }
HERE
  
}

resource "consul_acl_token" "anonymous_token" {
    policies = [consul_acl_policy.anonymous.name]
    description = "Anonymous Token"
    local = true
}

data "consul_acl_token_secret_id" "anonymous_token_secret" {
    accessor_id = consul_acl_token.anonymous_token.id
}