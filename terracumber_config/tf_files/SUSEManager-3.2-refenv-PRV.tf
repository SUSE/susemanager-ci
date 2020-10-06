// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Manager-3.2/job/manager-3.2-reference-PRV"
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
  default = "Manager-3.2"
}

// Not really used in this pipeline, as we do not run cucumber
variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

// Not really used in this pipeline, as we do not send emails on success (no cucumber results)
variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results REF3.2-PRV $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results REF3.2-PRV: Environment setup failed"
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
  uri = "qemu+tcp://metropolis.mgr.prv.suse.net/system"
}

module "base" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  
  name_prefix       = "suma-ref32-"
  use_avahi         = false
  domain            = "mgr.prv.suse.net"
  images            = ["centos7o", "sles12sp4o", "ubuntu1804o"]
  mirror            = "minima-mirror.mgr.prv.suse.net"
  use_mirror_images = true

  provider_settings = {
    pool         = "ssd"
    network_name = null
    bridge       = "br1"
  }
}

module "server" {
  source                  = "./modules/server"
  base_configuration      = module.base.configuration
  product_version         = "3.2-nightly"
  name                    = "srv"
  image                   = "sles12sp4o"

  monitored               = true
  use_os_released_updates = true
  disable_download_tokens = false
  from_email              = "root@suse.de"
  channels = [
    "sles12-sp4-pool-x86_64",
    "sles12-sp4-updates-x86_64",
    "sle-module-containers12-pool-x86_64-sp4",
    "sle-module-containers12-updates-x86_64-sp4"]

  provider_settings = {
    mac    = "52:54:00:c6:48:b9"
    memory = 8192
  }
}

module "suse-client" {
  source             = "./modules/client"
  base_configuration = module.base.configuration
  product_version    = "3.2-nightly"
  name               = "cli-sles12"
  image              = "sles12sp4o"

  server_configuration    = module.server.configuration
  use_os_released_updates = true

  provider_settings = {
    mac = "52:54:00:93:17:5f"
  }
}

module "suse-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "3.2-nightly"
  name               = "min-sles12"
  image              = "sles12sp4o"

  server_configuration    = module.server.configuration
  use_os_released_updates = true

  provider_settings = {
    mac = "52:54:00:a0:d0:ce"
  }
}

module "build-host" {
  source                  = "./modules/minion"
  base_configuration      = module.base.configuration
  product_version         = "3.2-nightly"
  name                    = "min-build"
  image                   = "sles12sp4o"
  server_configuration    = module.server.configuration

  provider_settings = {
    mac = "52:54:00:00:00:19"
  }
}


module "redhat-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "3.2-nightly"
  name               = "min-centos7"
  image              = "centos7o"

  server_configuration = module.server.configuration

  provider_settings = {
    mac = "52:54:00:33:1a:ad"
  }
}

module "debian-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "3.2-nightly"
  name               = "min-ubuntu1804"
  image              = "ubuntu1804o"

  server_configuration = module.server.configuration

  provider_settings = {
    mac = "52:54:00:e0:ed:07"
  }
}
