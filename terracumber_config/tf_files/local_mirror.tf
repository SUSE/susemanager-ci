// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-manager-mu-cloud"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='Uyuni' && run-testsuite"
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
  default = "Results Uyuni-Master $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Uyuni-Master: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = string
  default = "mnoel@suse.de"
}

variable "MAIL_TO" {
  type = string
  default = "mnoel@suse.de"
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
  default = null
  // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type = string
  default = null
  // Not needed for master, as it is public
}

variable "SSH_KEY" {
  type = string
  default = "/home/jenkins/.ssh/id_rsa.pub"
}

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

locals {
  pool = "ssd"
}

module "base" {
  source = "./modules/base"
  ssh_key_path = var.SSH_KEY
  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "mirror-mu-aws-"
  images = [
    "opensuse155o"]

  provider_settings = {
    pool = local.pool
    network_name = null
    bridge = "br0"
  }
}

module "mirror" {
  source = "./modules/mirror"

  base_configuration = module.base.configuration
  customize_minima_file = "mirror/etc/minima-customize.yaml"
  synchronize_immediately = true
  disable_cron = true
  image = "opensuse155o"
  volume_provider_settings = {
    pool = local.pool
  }
  provider_settings = {
    mac                = "52:54:00:ba:b7:98"
    memory             = 4096
  }
}

output "local_mirrors_public_name" {
  value = module.mirror.configuration.hostnames
}

output "local_mirrors_public_ip" {
  value = module.mirror.configuration.ipaddrs
}
