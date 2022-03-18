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
  default = "hub-reporting-beta3"
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
  default = "galaxy-ci@suse.de"
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
  uri = "qemu+tcp://salzbreze.mgr.suse.de/system"
}

module "base_core" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["centos7o", "opensuse152o", "opensuse153o","sles15sp3o", "sles15sp4o"]
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
  source = "./modules/server"
  base_configuration = module.base_core.configuration
  name = "hub"
  product_version = "head"
  additional_repos = {
    Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Orion/SLE_15_SP4/"
  }
  image = "sles15sp4o"
  provider_settings = {
    mac = "aa:b2:93:01:01:42"
  }
}

module "prh1" {
  source = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version = "head"
  name = "prh1"
  additional_repos = {
    Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Orion/SLE_15_SP4/"
  }
  auto_accept                    = true
  use_os_released_updates        = false
  from_email                     = "root@suse.de"
  register_to_server = module.hub.configuration.hostname
  image = "sles15sp4o"
  provider_settings = {
    mac = "aa:b2:93:01:01:43"
  }
}

module "prh2" {
  source = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version = "head"
  name = "prh2"
  additional_repos = {
    Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Orion/SLE_15_SP4/"
  }
  auto_accept                    = false
  use_os_released_updates        = false
  from_email                     = "root@suse.de"
  register_to_server = module.hub.configuration.hostname
  image = "sles15sp4o"
  provider_settings = {
    mac = "aa:b2:93:01:01:44"
  }
}


module "min-sles15sp3" {
  source = "./modules/minion"
  base_configuration = module.base_core.configuration
  name = "min-sles15sp3"
  image = "sles15sp3o"
  server_configuration = module.prh1.configuration
  use_os_released_updates = false
  provider_settings = {
    mac = "aa:b2:93:01:01:45"
  }
}

module "min-centos7" {
  source = "./modules/minion"
  base_configuration = module.base_core.configuration
  name = "min-centos7"
  image = "centos7o"
  server_configuration = module.prh1.configuration
  use_os_released_updates = false
  provider_settings = {
    mac = "aa:b2:93:01:01:46"
  }
}

module "controller" {
  source = "./modules/controller"
  base_configuration = module.base_core.configuration
  name = "ctl"
  no_auth_registry = "registry.mgr.suse.de"
  auth_registry = "portus.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"

  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  server_http_proxy = "galaxy-proxy.mgr.suse.de:3128"
  
  server_configuration = module.prh1.configuration

  sle15sp3_minion_configuration = module.min-sles15sp3.configuration
  centos7_minion_configuration = module.min-centos7.configuration

  provider_settings = {
    mac = "aa:b2:93:01:01:41"
  }
}

output "configuration" {
  value = module.controller.configuration
}
