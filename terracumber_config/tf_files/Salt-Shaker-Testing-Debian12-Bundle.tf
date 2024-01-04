// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/salt/job/manager-salt-shaker-products-testing-debian12-bundle"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "echo EXECUTE SALT TESTS HERE"
}
variable "CUCUMBER_BRANCH" {
  type = string
  default = "master"
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "Results Salt Shaker - products:testing - Debian12 Salt Bundle $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-salt-shaker.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Salt Shaker - products:testing - Debian12 Salt Bundle: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-salt-shaker-env-fail.txt"
}

variable "MAIL_FROM" {
  type = string
  default = "salt-ci@suse.de"
}

variable "MAIL_TO" {
  type = string
  default = "salt-ci@suse.de"
}

// sumaform specific variables
variable "SCC_USER" {
  type = string
  default = null // Not needed for Salt tests
}

variable "SCC_PASSWORD" {
  type = string
  default = null // Not needed for Salt tests
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
  uri = "qemu+tcp://suma-03.mgr.suse.de/system"
}

module "base" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br0"
  }

  images = [ "debian12o" ]
}

module "salt-shaker-products-testing" {
  source             = "./modules/salt_testenv"
  base_configuration = module.base.configuration

  name               = "salt-shaker-products-testing-debian12-bundle"
  image              = "debian12o"
  salt_obs_flavor    = "products:testing"
}

output "configuration" {
  value = module.salt-shaker-products-testing.configuration
}
