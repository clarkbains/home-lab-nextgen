
terraform {
  required_providers {
    consul = {
      
      source = "hashicorp/consul"
      version = "2.20.0"
    }
    nomad = {
      source = "hashicorp/nomad"
      version = "2.1.0"
    }
  }
  backend "s3" {
    bucket = "terraform-cbains"
    key    = "homelab/v1/nomad"
    region = "ca-central-1"
  }
}

provider "consul" {
  address    = var.consul_http
  datacenter = var.consul_dc
  token = var.consul_token
}

provider "nomad" {
  address    = var.nomad_http
  secret_id = var.nomad_token
}



