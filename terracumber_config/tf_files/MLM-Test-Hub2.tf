
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://suma-05.mgr.suse.de/system"
}

module "base_core" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["opensuse156o", "sles15sp5o", "sles15sp7o"]
  use_avahi    = false
  name_prefix  = "mlm-qetesthub-"
  domain       = "mgr.suse.de"

  provider_settings = {
    pool         = "ssd"
    network_name = null
    bridge       = "br0"
  }
  ssh_key_path      = var.PUBLIC_SSH_KEY_PATH
}

module "hub" {
  source = "./modules/server_containerized"
  base_configuration = module.base_core.configuration
  name = "hub"
  product_version = "head-staging"
  image = "sles15sp7o"
  provider_settings = {
    mac = "aa:b2:93:01:01:c4"
    memory = 10240
    vcpu = 8
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
  runtime              = "podman"
  container_repository = "registry.suse.de/suse/sle-15-sp7/update/products/multilinuxmanager52/totest/containerfile"
  container_tag        = "latest"
  ssh_key_path      = var.PUBLIC_SSH_KEY_PATH
}

module "prh1" {
  source = "./modules/server_containerized"
  base_configuration = module.base_core.configuration
  product_version = "head-staging"
  name = "prh1"
  auto_accept                    = true
  from_email                     = "root@suse.de"
  register_to_server = module.hub.configuration
  image = "sles15sp7o"
  provider_settings = {
    mac = "aa:b2:93:01:01:c5"
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
  runtime              = "podman"
  container_repository = "registry.suse.de/suse/sle-15-sp7/update/products/multilinuxmanager52/totest/containerfile"
  container_tag        = "latest"
  ssh_key_path      = var.PUBLIC_SSH_KEY_PATH
}

module "prh2" {
  source = "./modules/server_containerized"
  base_configuration = module.base_core.configuration
  product_version = "head-staging"
  name = "prh2"
  auto_accept                    = true
  from_email                     = "root@suse.de"
  register_to_server = module.hub.configuration
  image = "sles15sp7o"
  provider_settings = {
    mac = "aa:b2:93:01:01:c6"
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
  runtime              = "podman"
  container_repository = "registry.suse.de/suse/sle-15-sp7/update/products/multilinuxmanager52/totest/containerfile"
  container_tag        = "latest"
  ssh_key_path      = var.PUBLIC_SSH_KEY_PATH
}


module "min-sles15sp5" {
  source = "./modules/minion"
  base_configuration = module.base_core.configuration
  name = "min-sles15sp5"
  image = "sles15sp5o"
  server_configuration = module.prh1.configuration
  provider_settings = {
    mac = "aa:b2:93:01:01:c7"
  }
  ssh_key_path      = var.PUBLIC_SSH_KEY_PATH
}

module "min-sles15sp7" {
  source = "./modules/minion"
  base_configuration = module.base_core.configuration
  name = "min-sles15sp7"
  image = "sles15sp7o"
  server_configuration = module.prh2.configuration
  provider_settings = {
    mac = "aa:b2:93:01:01:c8"
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
  ssh_key_path      = var.PUBLIC_SSH_KEY_PATH
}

module "controller" {
  source = "./modules/controller"
  base_configuration = module.base_core.configuration
  name = "controller"
  no_auth_registry = "registry.mgr.suse.de"
  auth_registry = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"

  cc_ptf_username = var.SCC_PTF_USER
  cc_ptf_password = var.SCC_PTF_PASSWORD

  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/temporary"

  # server_http_proxy = "http-proxy.mgr.suse.de:3128"
  
  server_configuration = module.prh1.configuration

  sle15sp4_minion_configuration = module.min-sles15sp7.configuration
  sle15sp5_minion_configuration = module.min-sles15sp5.configuration

  provider_settings = {
    mac = "aa:b2:93:01:01:c3"
  }
}

output "configuration" {
  value = {
    hub  = module.hub.configuration
    prh1 = module.prh1.configuration
    prh2 = module.prh2.configuration
    min-sles15sp7 = module.min-sles15sp7.configuration
    min-sles15sp5 = module.min-sles15sp5.configuration
    controller = module.controller.configuration
  }
}
