// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-master-infra-reference-NUE"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='Uyuni' && run-testsuite"
}

// Not really used in this pipeline, as we do not run cucumber
variable "CUCUMBER_GITREPO" {
  type = string
  default = "https://github.com/uyuni-project/uyuni.git"
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
  default = "Results Uyuni RefMaster-NUE $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Uyuni RefMaster-NUE: Environment setup failed"
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

  name_prefix = "uyuni-refmaster-"
  use_avahi   = false
  domain      = "mgr.suse.de"
  images      = ["centos7o", "opensuse154o", "sles15sp1o", "sles15sp2o", "sles15sp3o", "ubuntu2204o"]

  provider_settings = {
    pool         = "ssd"
    network_name = null
    bridge       = "br2"
  }
}

module "server" {
  source             = "./modules/server"
  base_configuration = module.base.configuration
  product_version    = "uyuni-master"
  name               = "srv"
  monitored               = true
  use_os_released_updates = true
  disable_download_tokens = false
  from_email              = "root@suse.de"
  postgres_log_min_duration = 0
  channels                = ["sle-product-sles15-sp3-pool-x86_64", "sle-product-sles15-sp3-updates-x86_64", "sle-module-basesystem15-sp3-pool-x86_64", "sle-module-basesystem15-sp3-updates-x86_64", "sle-module-containers15-sp3-pool-x86_64", "sle-module-containers15-sp3-updates-x86_64", "sle-module-server-applications15-sp3-pool-x86_64", "sle-module-server-applications15-sp3-updates-x86_64"]

  additional_repos        = { }
  provider_settings = {
    mac = "aa:b2:93:01:00:e1"
    memory = 8192
  }
}

module "suse-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "uyuni-master"
  name               = "min-sles15"
  image              = "sles15sp3o"

  server_configuration    = module.server.configuration
  use_os_released_updates = true

  provider_settings = {
    mac = "aa:b2:93:01:00:e6"
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "redhat-minion" {
  source               = "./modules/minion"
  base_configuration   = module.base.configuration
  product_version      = "uyuni-master"
  name                 = "min-centos7"
  image                = "centos7o"
  server_configuration = module.server.configuration

  provider_settings = {
    mac = "aa:b2:93:01:00:e9"
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
  product_version      = "uyuni-master"
  name                 = "min-ubuntu2204"
  image                = "ubuntu2204o"
  server_configuration = module.server.configuration

  provider_settings = {
    mac = "aa:b2:93:01:00:eb"
  }
  additional_packages = [ "venv-salt-minion" ]

  // FIXME: cloudl-init fails if venv-salt-minion is not avaiable
  // We can set "install_salt_bundle = true" as soon as venv-salt-minion is available Uyuni:Stable
  install_salt_bundle = false
}

module "build-host" {
  source                  = "./modules/build_host"
  base_configuration      = module.base.configuration
  product_version         = "uyuni-master"
  name                    = "min-build"
  image                   = "sles15sp3o"
  server_configuration    = module.server.configuration

  provider_settings = {
    mac = "aa:b2:93:01:00:ed"
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "kvm-minion" {
  source               = "./modules/virthost"
  base_configuration   = module.base.configuration
  product_version      = "uyuni-master"
  name                 = "min-kvm"
  image                = "sles15sp3o"
  server_configuration = module.server.configuration

  provider_settings = {
    mac = "aa:b2:93:01:00:ee"
  }
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}
