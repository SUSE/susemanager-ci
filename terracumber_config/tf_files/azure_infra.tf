// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://jenkins.mgr.suse.de/job/manager-build-validation-Azure-infra"
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
  default = "Results Azure BV infra $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Azure BV infra: Environment setup failed"
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
variable "LOCATION" {
  type = string
  default = null
}

variable "KEY_FILE" {
  type = string
  default = "/home/jenkins/.ssh/testing-suma.pem"
}

// Public half of KEY_FILE, installed on the instances
variable "PUBLIC_KEY_FILE" {
  type = string
}

variable "ALLOWED_IPS" {
  type = list(string)
  default = []
}

// Prefix of the shared infrastructure (resource group, virtual network, subnets, bastion): server pipelines look it up by this prefix
variable "NAME_PREFIX" {
  type = string
  default = "mlm-bv-azure-"
}

// The subscription is taken from ARM_SUBSCRIPTION_ID
provider "azurerm" {
  features {}
}

module "base" {
  source            = "./modules/base"
  // Set product_version to empty to get the public tools repositories
  product_version   = ""
  name_prefix       = var.NAME_PREFIX
  use_avahi         = false
  // Hosts are accessed with KEY_FILE only: the sumaform default ~/.ssh/id_ed25519.pub does not exist on Jenkins agents
  ssh_key_path      = null
  provider_settings = {
    location            = var.LOCATION
    ssh_allowed_ips     = var.ALLOWED_IPS
    key_file            = var.KEY_FILE
    public_key_location = var.PUBLIC_KEY_FILE
  }
}

output "bastion_public_name" {
  value = lookup(module.base.configuration, "bastion_host", null)
}
