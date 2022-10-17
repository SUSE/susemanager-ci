// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-Head/job/manager-Head-infra-reference-NUE"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

// Not really used in this pipeline, as we do not run cucumber
variable "CUCUMBER_GITREPO" {
  type = string
  default = "https://github.com/SUSE/spacewalk.git"
}

// Not really used in this pipeline, as we do not run cucumber
variable "CUCUMBER_BRANCH" {
  type = string
  default = "master"
}

// Not really used in this pipeline, as we do not run cucumber
variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

// Not really used in this pipeline, as we do not send emails on success (no cucumber results)
variable "MAIL_SUBJECT" {
  type = string
  default = "Results RefHead-NUE $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results RefHead-NUE: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-refenv-fail.txt"
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
  uri = "qemu+tcp://cokerunner.mgr.suse.de/system"
}

module "base" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  name_prefix = "suma-refhead-"
  use_avahi   = false
  domain      = "mgr.suse.de"
  images      = ["rocky8o", "sles15sp1o", "sles15sp2o", "sles15sp3o", "sles15sp4o", "ubuntu2204o"]
  provider_settings = {
    pool         = "ssd"
    network_name = null
    bridge       = "br2"
  }
}

module "server" {
  source             = "./modules/server"
  base_configuration = module.base.configuration
  product_version    = "head"
  name               = "srv"
  monitored               = true
  use_os_released_updates = true
  disable_download_tokens = false
  from_email              = "root@suse.de"
  postgres_log_min_duration = 0
  channels                = ["sle-product-sles15-sp3-pool-x86_64", "sle-product-sles15-sp3-updates-x86_64", "sle-module-basesystem15-sp3-pool-x86_64", "sle-module-basesystem15-sp3-updates-x86_64", "sle-module-containers15-sp3-pool-x86_64", "sle-module-containers15-sp3-updates-x86_64", "sle-manager-tools15-pool-x86_64-sp3", "sle-manager-tools15-updates-x86_64-sp3", "sle-module-server-applications15-sp3-pool-x86_64", "sle-module-server-applications15-sp3-updates-x86_64"]

  provider_settings = {
    mac = "aa:b2:93:01:00:c1"
    memory = 8192
  }
}

module "suse-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "head"
  name               = "min-sles15"
  image              = "sles15sp3o"

  server_configuration    = module.server.configuration
  use_os_released_updates = true

  provider_settings = {
    mac = "aa:b2:93:01:00:c6"
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "redhat-minion" {
  source               = "./modules/minion"
  base_configuration   = module.base.configuration
  product_version      = "head"
  name                 = "min-rocky8"
  image                = "rocky8o"
  server_configuration = module.server.configuration

  provider_settings = {
    mac = "aa:b2:93:01:00:c9"
    // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
    // Also, openscap cannot run with less than 1.25 GB of RAM
    memory = 2048
    vcpu = 2
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "debian-minion" {
  source               = "./modules/minion"
  base_configuration   = module.base.configuration
  product_version      = "head"
  name                 = "min-ubuntu2204"
  image                = "ubuntu2204o"
  server_configuration = module.server.configuration

  provider_settings = {
    mac = "aa:b2:93:01:00:cb"
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "build-host" {
  source                  = "./modules/build_host"
  base_configuration      = module.base.configuration
  product_version         = "head"
  name                    = "min-build"
  image                   = "sles15sp3o"
  server_configuration    = module.server.configuration

  provider_settings = {
    mac = "aa:b2:93:01:00:cd"
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "kvm-minion" {
  source               = "./modules/virthost"
  base_configuration   = module.base.configuration
  product_version      = "head"
  name                 = "min-kvm"
  image                = "sles15sp3o"
  server_configuration = module.server.configuration

  provider_settings = {
    mac = "aa:b2:93:01:00:ce"
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}
