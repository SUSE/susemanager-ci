terraform {
  required_version = ">= 1.6.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://${var.BASE_CONFIGURATIONS.base_core["hypervisor"]}/system"
}

module "base_core" {
  source = "./modules/base"

  cc_username     = var.SCC_USER
  cc_password     = var.SCC_PASSWORD
  product_version = var.PRODUCT_VERSION != null ? var.PRODUCT_VERSION : var.ENVIRONMENT_CONFIGURATION.product_version
  name_prefix     = var.ENVIRONMENT_CONFIGURATION.name_prefix
  use_avahi       = false
  domain          = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain

  images = lookup(var.BASE_CONFIGURATIONS.base_core, "images", [
    "sles12sp5o",
    "sles15sp3o", "sles15sp4o", "sles15sp5o", "sles15sp6o", "sles15sp7o",
    "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "slemicro55o",
    "slmicro60o", "slmicro61o",
    "almalinux8o", "almalinux9o",
    "amazonlinux2023o",
    "centos7o",
    "libertylinux9o",
    "oraclelinux9o",
    "rocky8o", "rocky9o",
    "ubuntu2204o", "ubuntu2404o",
    "debian12o",
    "opensuse156o"
  ])

  mirror            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].mirror
  use_mirror_images = true
  testsuite         = true

  provider_settings = {
    pool               = var.BASE_CONFIGURATIONS.base_core["pool"]
    bridge             = var.BASE_CONFIGURATIONS.base_core["bridge"]
    additional_network = var.BASE_CONFIGURATIONS.base_core["additional_network"]
  }
}

module "build_validation_module" {
  source = "./modules/build_validation"

  providers = {
    libvirt.host_old_sle = libvirt
    libvirt.host_new_sle = libvirt
    libvirt.host_rhlike  = libvirt
    libvirt.host_deblike = libvirt
    libvirt.host_retail  = libvirt
  }

  module_base_configurations = {
    default = module.base_core.configuration
  }

  # --- VARIABLES ---
  environment_configuration       = var.ENVIRONMENT_CONFIGURATION
  base_configurations             = var.BASE_CONFIGURATIONS
  platform_location_configuration = var.PLATFORM_LOCATION_CONFIGURATION
  location                        = var.LOCATION
  product_version                 = var.PRODUCT_VERSION != null ? var.PRODUCT_VERSION : var.ENVIRONMENT_CONFIGURATION.product_version

  scc_user         = var.SCC_USER
  scc_password     = var.SCC_PASSWORD
  scc_ptf_user     = var.SCC_PTF_USER
  scc_ptf_password = var.SCC_PTF_PASSWORD
  zvm_admin_token  = var.ZVM_ADMIN_TOKEN

  git_user          = var.GIT_USER
  git_password      = var.GIT_PASSWORD
  cucumber_gitrepo  = var.CUCUMBER_GITREPO
  cucumber_branch   = var.CUCUMBER_BRANCH

  server_container_repository = var.SERVER_CONTAINER_REPOSITORY
  server_container_image      = var.SERVER_CONTAINER_IMAGE
  server_additional_repos     = var.SERVER_ADDITIONAL_REPOS
  proxy_container_repository  = var.PROXY_CONTAINER_REPOSITORY
  proxy_additional_repos      = var.PROXY_ADDITIONAL_REPOS
  base_os                     = var.BASE_OS
}

output "configuration" {
  value = {
    controller  = module.build_validation_module.configuration.controller
    server      = module.build_validation_module.configuration.server_configuration
  }
}