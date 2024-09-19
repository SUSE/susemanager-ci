// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-Test/job/manager-TEST-Hub-acceptance-tests"
}

variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='Uyuni' && run-testsuite #TODO run only sanity, core and hub tests, including reporting"
}

variable "CUCUMBER_GITREPO" {
  type = string
  default = "https://github.com/uyuni-project/uyuni.git"
}

variable "CUCUMBER_BRANCH" {
  type = string
  default = "master"
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "Results TEST-HUB $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results TEST-HUB : Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = string
  default = "jenkins@suse.de"
}

variable "MAIL_TO" {
  type = string
  default = "galaxy-ci@suse.de"
}

// sumaform specific variables
variable "SCC_USER" {
  type = string
}

variable "SCC_PASSWORD" {
  type = string
}

variable "GIT_USER" {
  type = string
  default = null // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type = string
  default = null // Not needed for master, as it is public
}

terraform {
  required_version = "1.0.10"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://cthulhu.mgr.suse.de/system"
}

module "base_core" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["rocky8o", "opensuse155o", "sles15sp5o", "slemicro55o"]
  use_avahi    = false
  name_prefix  = "suma-testhub-"
  domain       = "mgr.suse.de"

  provider_settings = {
    pool         = "ssd"
    network_name = null
    bridge       = "br0"
  }
}

module "hub" {
  source = "./modules/server_containerized"
  base_configuration = module.base_core.configuration
  name = "hub"
  product_version = "head"
  image = "slemicro55o"
  provider_settings = {
    mac = "aa:b2:93:01:01:31"
    memory = 10240
    vcpu = 8
  }
  runtime = "podman"
  container_repository = "registry.suse.de/devel/galaxy/manager/head/containerfile"
  container_tag = "latest"
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "prh1" {
  source = "./modules/server_containerized"
  base_configuration = module.base_core.configuration
  product_version = "head"
  name = "prh1"
  auto_accept                    = true
  from_email                     = "root@suse.de"
  register_to_server = module.hub.configuration
  image = "slemicro55o"
  provider_settings = {
    mac = "aa:b2:93:01:01:32"
  }
  runtime = "podman"
  container_repository = "registry.suse.de/devel/galaxy/manager/head/containerfile"
  container_tag = "latest"
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

/*
module "prh2" {
  source = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version = "4.3-nightly"
  name = "prh2"
  auto_accept                    = true
  from_email                     = "root@suse.de"
  register_to_server = module.hub.configuration
  image = "sles15sp4o"
  provider_settings = {
    mac = "aa:b2:93:01:01:33"
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}


module "min-sles15sp5" {
  source = "./modules/minion"
  base_configuration = module.base_core.configuration
  name = "min-sles15sp5"
  image = "sles15sp5o"
  server_configuration = module.prh1.configuration
  provider_settings = {
    mac = "aa:b2:93:01:01:34"
  }
}

module "min-sles15sp4" {
  source = "./modules/minion"
  base_configuration = module.base_core.configuration
  name = "min-sles15sp4"
  image = "sles15sp4o"
  server_configuration = module.prh2.configuration
  provider_settings = {
    mac = "aa:b2:93:01:01:35"
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}
*/

module "controller" {
  source = "./modules/controller"
  base_configuration = module.base_core.configuration
  name = "ctl"
  no_auth_registry = "registry.mgr.suse.de"
  auth_registry = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"

  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  server_http_proxy = "http-proxy.mgr.suse.de:3128"
  
  server_configuration = module.prh1.configuration

  //sle15sp4_minion_configuration = module.min-sles15sp4.configuration
  //sle15sp5_minion_configuration = module.min-sles15sp5.configuration

  provider_settings = {
    mac = "aa:b2:93:01:01:30"
  }
}

output "configuration" {
  value = {
    hub  = module.hub.configuration
    prh1 = module.prh1.configuration
    //prh2 = module.prh2.configuration
    //min-sles15sp4 = module.min-sles15sp4.configuration
    //min-sles15sp5 = module.min-sles15sp5.configuration
    controller = module.controller.configuration
  }
}
