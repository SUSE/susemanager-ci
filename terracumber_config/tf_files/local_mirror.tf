// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://jenkins.mgr.suse.de/job/manager-build-validation-AWS-infra"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = string
  default = "https://github.com/SUSE/spacewalk.git"
}

variable "CUCUMBER_BRANCH" {
  type = string
  default = "Manager-5.2"
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "Results AWS infra local mirror $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results AWs infra local mirror: Environment setup failed"
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
  default = null
  // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type = string
  default = null
  // Not needed for master, as it is public
}

// Jenkins agents have no ~/.ssh/id_ed25519.pub: use the controller key shipped with sumaform,
// its private half is used by the pipeline to reach the mirror (see local_mirror_ssh_private_key)
variable "SSH_KEY" {
  type = string
  default = "./salt/controller/id_ed25519.pub"
}

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
    "opensuse160o"]

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
  // Content is copied to the AWS mirror via rsync over SSH: no host mounts this mirror via NFS
  nfs_server = false
  image = "opensuse160o"
  volume_provider_settings = {
    pool = local.pool
  }
  provider_settings = {
    memory             = 4096
    // The mirror is not in DNS (the agent cannot resolve tf.local): connect via its DHCP lease IP
    use_dhcp_ip        = true
  }
}

output "local_mirrors_public_name" {
  value = module.mirror.configuration.hostnames
}

output "local_mirrors_public_ip" {
  value = module.mirror.configuration.ipaddrs
}

output "local_mirror_ssh_private_key" {
  value = abspath(trimsuffix(var.SSH_KEY, ".pub"))
}
