// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-Head/job/manager-Head-infra-reference-mcp-server"
}

// Not really used in this pipeline, as we do not send emails on success (no cucumber results)
variable "MAIL_SUBJECT" {
  type = string
  default = "Results RefHead-MCP-Server $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results RefHead-MCP-Server: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-refenv-fail.txt"
}

variable "MAIL_FROM" {
  type = string
  default = "jenkins@suse.de"
}

variable "MAIL_TO" {
  type = string
  default = "galaxy-noise@suse.de"
}

variable "GIT_USER" {
  type = string
  default = null // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type = string
  default = null // Not needed for master, as it is public
}

// Not used, but required for Terracumber...
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

// Not used, but required for Terracumber...
variable "CUCUMBER_GITREPO" {
  type = string
  default = "https://github.com/uyuni-project/uyuni.git"
}

// Not used, but required for Terracumber...
variable "CUCUMBER_BRANCH" {
  type = string
  default = "master"
}

// Not used, but required for Terracumber...
variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
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
  uri = "qemu+tcp://suma-02.mgr.suse.de/system"
}


module "base" {
  product_version          = "head"
  source = "./modules/base"

  name_prefix = "mlm-ref-head-"
  use_avahi   = false
  domain      = "mgr.suse.de"
  images = ["sles15sp7o"]
  testsuite = false

  provider_settings = {
    network_name = null
    pool = "ssd"
    bridge = "br0"
  }
}

module "sles15sp7_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  name               = "mcp-server"
  image              = "sles15sp7o"
  server_configuration = null
  auto_connect_to_master = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  provider_settings = {
    mac = "aa:b2:93:01:00:ce"
    memory = 4096
    vcpu = 2
  }

}

output "configuration" {
  value = module.base.configuration
}
