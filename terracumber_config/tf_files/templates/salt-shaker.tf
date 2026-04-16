terraform {
  required_version = ">= 1.6.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

locals {
  libvirt_uri = "qemu+tcp://suma-04.mgr.suse.de/system"
  env         = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT]
}

provider "libvirt" {
  uri = local.libvirt_uri
}

module "base" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  use_avahi   = false
  domain      = "mgr.suse.de"

  provider_settings = {
    pool         = "ssd"
    network_name = null
    bridge       = "br1"
    libvirt_uri  = local.libvirt_uri
  }

  images = [local.env.image]
}

module "salt-shaker-products-next" {
  source             = "./modules/salt_testenv"
  base_configuration = module.base.configuration

  name              = "salt-shaker-products-next-${var.ENVIRONMENT}"
  image             = local.env.image
  salt_obs_flavor   = local.env.salt_obs_flavor
  provider_settings = {
    mac = local.env.mac_address
  }
}

output "configuration" {
  value = module.salt-shaker-products-next.configuration
}
