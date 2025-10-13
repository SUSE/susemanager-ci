terraform {
  required_version = "1.0.10"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.8.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://suma-05.mgr.suse.de/system"
}

module "base" {
  source            = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = "5.1-released"
  name_prefix   = "${var.ENVIRONMENT}-"
  use_avahi         = false
  domain            = "mgr.suse.de"
  images            = [ "sles15sp6o", "opensuse156o", "slmicro61o" ]

  mirror            = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images = true

  testsuite         = true

  provider_settings = {
    pool        = "ssd"
    bridge      = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].bridge
    additional_network = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].additional_network
  }
}

module "server_containerized" {
  source             = "./modules/server_containerized"
  base_configuration = module.base.configuration
  name               = "server"
  image              = "slmicro61o"
  provider_settings = {
    mac                = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["server"]
    data_pool          = "ssd"
  }

  main_disk_size        = 100
  repository_disk_size  = 1000
  database_disk_size    = 150
  runtime               = "podman"
  // Temporary workaround to see if we pass proxy stage. Also needs to be updated on next MU
  repository  = var.REPOSITORY
  tag         = "latest"
  server_mounted_mirror = "minima-mirror-ci-bv.mgr.suse.de"

  auto_accept                    = false
  monitored                      = true
  disable_firewall               = false
  allow_postgres_connections     = false
  skip_changelog_import          = false
  mgr_sync_autologin             = false
  create_sample_channel          = false
  create_sample_activation_key   = false
  create_sample_bootstrap_script = false
  publish_private_ssl_key        = false
  use_os_released_updates        = true
  disable_download_tokens        = false
  ssh_key_path                   = "./salt/controller/id_ed25519.pub"
  from_email                     = "root@suse.de"

  //server_additional_repos

}

module "proxy_containerized" {
  source             = "./modules/proxy_containerized"
  base_configuration = module.base.configuration
  name               = "proxy"
  image              = "slmicro61o"
  provider_settings  = {
    mac                = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["proxy"]
    memory             = 4096
  }
  server_configuration = {
    hostname = "${var.ENVIRONMENT}-server.mgr.suse.de"
    username = "admin"
    password = "admin"
  }

  runtime              = "podman"
  repository = var.REPOSITORY
  tag        = "latest"

  auto_configure        = false
  ssh_key_path          = "./salt/controller/id_ed25519.pub"

}

module "sles15sp6_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  name               = "sles15sp6-minion"
  image              = "sles15sp6o"
  provider_settings  = {
    mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["suse-minion"]
    vcpu   = 2
    memory = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

}

module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base.configuration
  name               = "controller"
  provider_settings = {
    mac                = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["controller"]
    memory             = 16384
    vcpu               = 8
  }
  swap_file_size = null

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration          = module.server_containerized.configuration
  proxy_configuration           = module.proxy_containerized.configuration
  sle15sp6_minion_configuration = module.sles15sp6_minion.configuration
}

output "configuration" {
  value = {
    controller = module.controller.configuration
  }
}
