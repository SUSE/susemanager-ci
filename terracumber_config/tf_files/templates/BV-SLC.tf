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

# Core Hypervisor
provider "libvirt" {
  uri = "qemu+tcp://${var.BASE_CONFIGURATIONS.base_core.hypervisor}/system"
}

# Old SLE Host
provider "libvirt" {
  alias = "host_old_sle_res"
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
  alias = "host_debian"
  uri   = "qemu+tcp://${var.BASE_CONFIGURATIONS.base_debian.hypervisor}/system"
}


# -------------------------------------------------------------------
# 2. DISTRIBUTED BASE CONFIGURATIONS
# -------------------------------------------------------------------

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
  providers = { libvirt = libvirt.host_old_sle_res }
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

# Base RES : EL and Liberty
module "base_res" {
  providers = { libvirt = libvirt.host_old_sle_res }
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
    pool        = var.BASE_CONFIGURATIONS.base_res.pool
    bridge      = var.BASE_CONFIGURATIONS.base_res.bridge
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

# Base Debian
module "base_debian" {
  providers = { libvirt = libvirt.host_debian }
  source    = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = var.PRODUCT_VERSION != null ? var.PRODUCT_VERSION : var.ENVIRONMENT_CONFIGURATION.product_version
  name_prefix       = var.ENVIRONMENT_CONFIGURATION.name_prefix
  use_avahi         = false
  domain            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain

  images            = var.BASE_CONFIGURATIONS.base_debian.images

  mirror            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].mirror
  use_mirror_images = true
  testsuite         = true

  provider_settings = {
    pool               = var.BASE_CONFIGURATIONS.base_debian.pool
    bridge             = var.BASE_CONFIGURATIONS.base_debian.bridge
  }
}

# -------------------------------------------------------------------
# 3. SHARED LOGIC INTEGRATION
# -------------------------------------------------------------------
module "bv_logic" {
  source = "./modules/build_validation_logic"

  # --- PROVIDER MAPPING ---
  # Plug the specific hardware providers into the logic slots
  providers = {
    libvirt.host_old_sle = libvirt.host_old_sle_res
    libvirt.host_new_sle = libvirt.host_new_sle
    libvirt.host_res     = libvirt.host_old_sle_res
    libvirt.host_debian  = libvirt.host_debian
    libvirt.host_retail  = libvirt.host_retail
  }

  # --- BASE MAPPING ---
  # Map roles to the specific distributed bases
  base_configurations = {
    default = module.base_core.configuration
    old_sle = module.base_old_sle.configuration
    new_sle = module.base_new_sle.configuration
    res     = module.base_res.configuration
    debian  = module.base_debian.configuration
    retail  = module.base_retail.configuration
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
    controller            = module.bv_logic.controller
    server_configuration  = module.bv_logic.server_configuration
  }
}