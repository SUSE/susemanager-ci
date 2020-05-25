// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Manager-4.0/job/manager-4.0-reference-NUE"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = "string"
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

// Not really used in this pipeline, as we do not run cucumber
variable "CUCUMBER_GITREPO" {
  type = "string"
  default = "https://github.com/SUSE/spacewalk.git"
}

// Not really used in this pipeline, as we do not run cucumber
variable "CUCUMBER_BRANCH" {
  type = "string"
  default = "Manager-4.0"
}

// Not really used in this pipeline, as we do not run cucumber
variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

// Not really used in this pipeline, as we do not send emails on success (no cucumber results)
variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results REF4.0-NUE $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results REF4.0-NUE: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins-refenv-fail.txt"
}

variable "MAIL_FROM" {
  type = "string"
  default = "galaxy-ci@suse.de"
}

variable "MAIL_TO" {
  type = "string"
  default = "galaxy-ci@suse.de"
}

// sumaform specific variables
variable "SCC_USER" {
  type = "string"
}

variable "SCC_PASSWORD" {
  type = "string"
}

provider "libvirt" {
  uri = "qemu+tcp://ramrod.mgr.suse.de/system"
}

module "base" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  name_prefix = "suma-ref40-"
  use_avahi   = false
  domain      = "mgr.suse.de"
  images      = ["centos7", "sles15sp1", "ubuntu1804"]

  provider_settings = {
    pool         = "ssd"
    network_name = null
    bridge       = "br0"
  }
}

module "srv" {
  source                  = "./modules/server"
  base_configuration      = module.base.configuration
  product_version         = "4.0-nightly"
  name                    = "srv"
  monitored               = true
  use_os_released_updates = true
  disable_download_tokens = false
  from_email              = "root@suse.de"
  channels                = ["sle-product-sles15-pool-x86_64", "sle-product-sles15-updates-x86_64", "sle-module-basesystem15-pool-x86_64", "sle-module-basesystem15-updates-x86_64", "sle-module-containers15-pool-x86_64", "sle-module-containers15-updates-x86_64"]

  provider_settings = {
    mac    = "AA:B2:93:00:00:50"
    memory = 8192
  }
}

module "cli-sles15" {
  source             = "./modules/client"
  base_configuration = module.base.configuration
  product_version    = "4.0-nightly"
  name               = "cli-sles15"
  image              = "sles15sp1"

  server_configuration    = module.srv.configuration
  use_os_released_updates = true

  provider_settings = {
    mac = "AA:B2:93:00:00:51"
  }
}

module "min-sles15" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.0-nightly"
  name               = "min-sles15"
  image              = "sles15sp1"

  server_configuration    = module.srv.configuration
  use_os_released_updates = true

  provider_settings = {
    mac = "AA:B2:93:00:00:52"
  }
}

module "min-build" {
  source                  = "./modules/minion"
  base_configuration      = module.base.configuration
  product_version         = "4.0-nightly"
  name                    = "min-build"
  image                   = "sles15sp1"
  server_configuration    = module.srv.configuration

  provider_settings = {
    mac = "AA:B2:93:00:00:59"
  }
}

module "minssh-sles15" {
  source                  = "./modules/sshminion"
  base_configuration      = module.base.configuration
  name                    = "minssh-sles15"
  image                   = "sles15sp1"

  use_os_released_updates = true

  provider_settings = {
    mac = "AA:B2:93:00:00:53"
  }
}

module "min-centos7" {
  source               = "./modules/minion"
  base_configuration   = module.base.configuration
  product_version      = "4.0-nightly"
  name                 = "min-centos7"
  image                = "centos7"
  server_configuration = module.srv.configuration

  provider_settings = {
    mac = "AA:B2:93:00:00:54"
  }
}

module "min-ubuntu1804" {
  source               = "./modules/minion"
  base_configuration   = module.base.configuration
  product_version      = "4.0-nightly"
  name                 = "min-ubuntu1804"
  image                = "ubuntu1804"
  server_configuration = module.srv.configuration

  provider_settings = {
    mac    = "AA:B2:93:00:00:57"
    memory = 1024
  }
}
