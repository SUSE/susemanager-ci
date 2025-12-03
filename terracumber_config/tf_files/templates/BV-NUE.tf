terraform {
  required_version = ">= 1.6.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
    feilong = {
      source  = "bischoff/feilong"
      version = "0.0.6"
    }
  }
}

# -------------------------------------------------------------------
# 1. PROVIDERS
# -------------------------------------------------------------------

# Main Hypervisor (NUE Local)
provider "libvirt" {
  uri = "qemu+tcp://${var.ENVIRONMENT_CONFIGURATION.base_core["hypervisor"]}/system"
}

module "base_core" {
  source = "./modules/base"

  cc_username     = var.SCC_USER
  cc_password     = var.SCC_PASSWORD
  product_version = var.PRODUCT_VERSION != null ? var.PRODUCT_VERSION : var.ENVIRONMENT_CONFIGURATION.product_version
  name_prefix     = var.ENVIRONMENT_CONFIGURATION.name_prefix
  use_avahi       = false
  domain          = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain

  # Images for all Intel/AMD minions
  images = [
    "sles12sp5o",
    "sles15sp3o", "sles15sp4o", "sles15sp5o", "sles15sp6o", "sles15sp7o",
    "slemicro51-ign", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "slemicro55o",
    "slmicro60o", "slmicro61o",
    "almalinux8o", "almalinux9o",
    "amazonlinux2023o",
    "centos7o",
    "libertylinux9o",
    "oraclelinux9o",
    "rocky8o", "rocky9o",
    "ubuntu2204o", "ubuntu2404o",
    "debian12o",
    "opensuse155o", "opensuse156o"
  ]

  mirror            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].mirror
  use_mirror_images = true
  testsuite         = true

  provider_settings = {
    pool               = var.BASE_CONFIGURATIONS.base_core["pool"]
    bridge             = var.BASE_CONFIGURATIONS.base_core["bridge"]
    additional_network = var.BASE_CONFIGURATIONS.base_core["additional_network"]
  }
}

# -------------------------------------------------------------------
# 4. SHARED LOGIC INTEGRATION
# -------------------------------------------------------------------
module "bv_logic" {
  source = "./modules/build_validation"

  providers = {
    libvirt.host_old_sle = libvirt
    libvirt.host_new_sle = libvirt
    libvirt.host_res     = libvirt
    libvirt.host_debian  = libvirt
    libvirt.host_retail  = libvirt
  }

  base_configurations = {
    default = module.base_core.configuration
  }

  # --- VARIABLES ---
  ENVIRONMENT_CONFIGURATION       = var.ENVIRONMENT_CONFIGURATION
  PLATFORM_LOCATION_CONFIGURATION = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION]
  LOCATION                        = var.LOCATION
  product_version                 = var.PRODUCT_VERSION != null ? var.PRODUCT_VERSION : var.ENVIRONMENT_CONFIGURATION.product_version

  SCC_USER         = var.SCC_USER
  SCC_PASSWORD     = var.SCC_PASSWORD
  SCC_PTF_USER     = var.SCC_PTF_USER
  SCC_PTF_PASSWORD = var.SCC_PTF_PASSWORD
  ZVM_ADMIN_TOKEN  = var.ZVM_ADMIN_TOKEN

  GIT_USER          = var.GIT_USER
  GIT_PASSWORD      = var.GIT_PASSWORD
  CUCUMBER_GITREPO  = var.CUCUMBER_GITREPO
  CUCUMBER_BRANCH   = var.CUCUMBER_BRANCH

  SERVER_CONTAINER_REPOSITORY = var.SERVER_CONTAINER_REPOSITORY
  SERVER_CONTAINER_IMAGE      = var.SERVER_CONTAINER_IMAGE
  PROXY_CONTAINER_REPOSITORY  = var.PROXY_CONTAINER_REPOSITORY
  BASE_OS                     = var.BASE_OS
}

output "configuration" {
  value = {
    controller            = module.bv_logic.configuration.controller
    server_configuration  = module.bv_logic.configuration.server_configuration
  }
}