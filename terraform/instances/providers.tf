terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.14"
    }
    macaddress = {
      source = "ivoronin/macaddress"
      version = "0.3.2"
    }
    opnsense = {
        source = "gxben/opnsense"
    }
  }
}

provider "opnsense" {
  uri      = var.opn_host
  user     = var.opn_user
  password = var.opn_password
}

provider "proxmox" {
  pm_api_url = var.pm_api_url
  pm_user = var.pm_user
  pm_password = var.pm_password
  pm_debug = true
}