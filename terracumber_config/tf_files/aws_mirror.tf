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
  default = "Results AWS BV infra $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results AWS BV infra: Environment setup failed"
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

variable "REGION" {
  type = string
  default = null
}

variable "AVAILABILITY_ZONE" {
  type = string
  default = null
}

variable "KEY_FILE" {
  type = string
  default = "/home/jenkins/.ssh/testing-suma.pem"
}

variable "KEY_NAME" {
  type = string
  default = "testing-suma"
}

variable "ALLOWED_IPS" {
  type = list(string)
  default = []
}

// Prefix of the shared infrastructure (VPC, subnets, bastion, mirror): server pipelines look it up by this prefix
variable "NAME_PREFIX" {
  type = string
  default = "mlm-bv-aws-"
}

// Set to false to deploy only the shared infrastructure (VPC, subnets, bastion), without the mirror
variable "MIRROR_ENABLED" {
  type = bool
  default = true
}

provider "aws" {
  region = var.REGION
}

module "base" {
  source            = "./modules/base"
  // Set product_version to null to get the public tools repositories
  product_version   = ""
  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  name_prefix       = var.NAME_PREFIX
  testsuite         = true
  use_avahi         = false
  use_eip_bastion   = false
  // Hosts are accessed with the AWS key pair only: the sumaform default ~/.ssh/id_ed25519.pub does not exist on Jenkins agents
  ssh_key_path      = null
  provider_settings = {
    availability_zone = var.AVAILABILITY_ZONE
    region            = var.REGION
    ssh_allowed_ips   = var.ALLOWED_IPS
    key_name          = var.KEY_NAME
    key_file          = var.KEY_FILE
    // sumaform defaults to opensuse156o, which is no longer in the AWS images list
    bastion_image     = "opensuse160o"
  }
}

// The mirror lives in the private subnet: it is reachable from other hosts in the VPC and through the bastion only
module "mirror" {
  count = var.MIRROR_ENABLED ? 1 : 0
  source = "./modules/mirror"
  base_configuration = module.base.configuration
  disable_cron = true
  // Content is served over HTTP only: no host mounts the mirror via NFS
  nfs_server = false
  // Any key will do: without one, the default state has no own state and the mirror "require: sls: default" fail
  ssh_key_path = "./salt/controller/id_ed25519.pub"
  image = "opensuse160o"
}


output "bastion_public_name" {
  value = lookup(module.base.configuration, "bastion_host", null)
}

output "aws_mirrors_private_name" {
  value = var.MIRROR_ENABLED ? module.mirror[0].configuration.hostnames : []
}
