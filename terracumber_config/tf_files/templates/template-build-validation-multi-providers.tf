terraform {
  required_version = ">= 1.6.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

# Core Hypervisor
provider "libvirt" {
  uri = "qemu+tcp://${var.BASE_CONFIGURATIONS.base_core.hypervisor}/system"
}

# Old SLE Host
provider "libvirt" {
  alias = "host_old_sle_rhlike"
  uri   = "qemu+tcp://${var.BASE_CONFIGURATIONS.base_old_sle.hypervisor}/system"
}

# New SLE Host
provider "libvirt" {
  alias = "host_new_sle"
  uri   = "qemu+tcp://${var.BASE_CONFIGURATIONS.base_new_sle.hypervisor}/system"
}

# Retail/Infrastructure Host
provider "libvirt" {
  alias = "host_retail"
  uri   = "qemu+tcp://${var.BASE_CONFIGURATIONS.retail.hypervisor}/system"
}

# Debian/Ubuntu Host
provider "libvirt" {
  alias = "host_deblike"
  uri   = "qemu+tcp://${var.BASE_CONFIGURATIONS.base_deblike.hypervisor}/system"
}

# Base Core : Core Infra + Main Testsuite images
module "base_core" {
  source = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = var.PRODUCT_VERSION != null ? var.PRODUCT_VERSION : var.ENVIRONMENT_CONFIGURATION.product_version
  name_prefix       = var.ENVIRONMENT_CONFIGURATION.name_prefix
  use_avahi         = false
  domain            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain

  images            = var.BASE_CONFIGURATIONS.base_core.images


  mirror            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].mirror
  use_mirror_images = true
  testsuite         = true

  provider_settings = {
    pool        = var.BASE_CONFIGURATIONS.base_core.pool
    bridge      = var.BASE_CONFIGURATIONS.base_core.bridge
  }
}

# Base Old SLE : SLES 12
module "base_old_sle" {
  providers = { libvirt = libvirt.host_old_sle_rhlike }
  source    = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = var.PRODUCT_VERSION != null ? var.PRODUCT_VERSION : var.ENVIRONMENT_CONFIGURATION.product_version
  name_prefix       = var.ENVIRONMENT_CONFIGURATION.name_prefix
  use_avahi         = false
  domain            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain

  images            = var.BASE_CONFIGURATIONS.base_old_sle.images

  mirror            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].mirror
  use_mirror_images = true
  testsuite         = true

  provider_settings = {
    pool        = var.BASE_CONFIGURATIONS.base_old_sle.pool
    bridge      = var.BASE_CONFIGURATIONS.base_old_sle.bridge
  }
}

# Base RedHat : EL and Liberty
module "base_rhlike" {
  providers = { libvirt = libvirt.host_old_sle_rhlike }
  source    = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = var.PRODUCT_VERSION != null ? var.PRODUCT_VERSION : var.ENVIRONMENT_CONFIGURATION.product_version
  name_prefix       = var.ENVIRONMENT_CONFIGURATION.name_prefix
  use_avahi         = false
  domain            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain

  images            = var.BASE_CONFIGURATIONS.base_old_sle.images

  mirror            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].mirror
  use_mirror_images = true
  testsuite         = true

  provider_settings = {
    pool        = var.BASE_CONFIGURATIONS.base_rhlike.pool
    bridge      = var.BASE_CONFIGURATIONS.base_rhlike.bridge
  }
}

# Base New SLE : SLES 15 + Micro
module "base_new_sle" {
  providers = { libvirt = libvirt.host_new_sle }
  source    = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = var.PRODUCT_VERSION != null ? var.PRODUCT_VERSION : var.ENVIRONMENT_CONFIGURATION.product_version
  name_prefix       = var.ENVIRONMENT_CONFIGURATION.name_prefix
  use_avahi         = false
  domain            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain

  images            = var.BASE_CONFIGURATIONS.base_new_sle.images

  mirror            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].mirror
  use_mirror_images = true
  testsuite         = true

  provider_settings = {
    pool        = var.BASE_CONFIGURATIONS.base_new_sle.pool
    bridge      = var.BASE_CONFIGURATIONS.base_new_sle.bridge
  }
}

module "base_retail" {
  providers = { libvirt = libvirt.host_retail }
  source    = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = var.PRODUCT_VERSION != null ? var.PRODUCT_VERSION : var.ENVIRONMENT_CONFIGURATION.product_version
  name_prefix       = var.ENVIRONMENT_CONFIGURATION.name_prefix
  use_avahi         = false
  domain            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain

  images            = var.BASE_CONFIGURATIONS.base_retail.images

  mirror            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].mirror
  use_mirror_images = true
  testsuite         = true

  provider_settings = {
    pool               = var.BASE_CONFIGURATIONS.base_retail.pool
    bridge             = var.BASE_CONFIGURATIONS.base_retail.bridge
    additional_network = var.BASE_CONFIGURATIONS.base_retail.additional_network
  }
}

# Base Deb-like minions
module "base_deblike" {
  providers = { libvirt = libvirt.host_deblike }
  source    = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = var.PRODUCT_VERSION != null ? var.PRODUCT_VERSION : var.ENVIRONMENT_CONFIGURATION.product_version
  name_prefix       = var.ENVIRONMENT_CONFIGURATION.name_prefix
  use_avahi         = false
  domain            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain

  images            = var.BASE_CONFIGURATIONS.base_deblike.images

  mirror            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].mirror
  use_mirror_images = true
  testsuite         = true

  provider_settings = {
    pool               = var.BASE_CONFIGURATIONS.base_deblike.pool
    bridge             = var.BASE_CONFIGURATIONS.base_deblike.bridge
  }
}

module "build_validation_module" {
  source = "./modules/build_validation"

  # --- PROVIDER MAPPING ---
  # Plug the specific hardware providers into the logic slots
  providers = {
    libvirt.host_old_sle = libvirt.host_old_sle_rhlike
    libvirt.host_new_sle = libvirt.host_new_sle
    libvirt.host_rhlike  = libvirt.host_old_sle_rhlike
    libvirt.host_deblike = libvirt.host_deblike
    libvirt.host_retail  = libvirt.host_retail
  }

  # --- BASE MAPPING ---
  # Map roles to the specific distributed bases
  module_base_configurations = {
    default = module.base_core.configuration
    old_sle = module.base_old_sle.configuration
    new_sle = module.base_new_sle.configuration
    rhlike  = module.base_rhlike.configuration
    deblike = module.base_deblike.configuration
    retail  = module.base_retail.configuration
  }

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
  proxy_container_repository  = var.PROXY_CONTAINER_REPOSITORY
  base_os                     = var.BASE_OS
}


output "configuration" {
  value = {
    controller  = module.build_validation_module.configuration.controller
    server      = module.build_validation_module.configuration.server_configuration
  }
}