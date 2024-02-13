
terraform {
  required_providers {
    consul = {
      source = "hashicorp/consul"
      version = "2.20.0"
    }
  }
}

provider "consul" {
  address    = var.consul_http
  datacenter = var.consul_dc
  token = var.consul_token
}

terraform {
  backend "s3" {
    bucket = "terraform-cbains"
    key    = "homelab/v1/consul"
    region = "ca-central-1"
  }
}
