// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-master-dev-acceptance-tests-code-coverage"
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
  default = "Results Uyuni-Master-test-code-coverage $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Uyuni-Master Code Coverage: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
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
  uri = "qemu+tcp://daiquiri.mgr.prv.suse.net/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "uyuni-master"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["opensuse154o", "sles15sp4o", "sles15sp3o"]

  use_avahi    = false
  name_prefix  = "suma-codecov-"
  domain       = "mgr.prv.suse.net"
  from_email   = "root@suse.com"

  mirror      = "minima-mirror.mgr.prv.suse.net"
  no_auth_registry = "registry.mgr.prv.suse.net"
  auth_registry      = "registry.mgr.prv.suse.net:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_prv"

  server_http_proxy = "http-proxy.mgr.prv.suse.net:3128"
  custom_download_endpoint = "ftp://minima-mirror.mgr.prv.suse.net:445"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:92:04:00:f0"
      }
    }
    server = {
      provider_settings = {
        mac = "aa:b2:92:04:00:f1"
        memory = 10240
      }
      server_mounted_mirror = "minima-mirror.mgr.prv.suse.net"
    }
    proxy = {
      provider_settings = {
        mac = "aa:b2:92:04:00:f2"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-minion = {
      image = "sles15sp4o"
      name = "min-sles15"
      provider_settings = {
        mac = "aa:b2:92:04:00:f4"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = "sles15sp4o"
      name = "minssh-sles15"
      provider_settings = {
        mac = "aa:b2:92:04:00:f5"
      }
      additional_packages = [ "venv-salt-minion", "iptables" ]
      install_salt_bundle = true
    }
  }
  provider_settings = {
    pool               = "default"
    network_name       = null
    bridge             = "br1"
    additional_network = "192.168.108.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
