// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Manager-3.2/job/manager-3.2-cucumber-PRV"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = "string"
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = "string"
  default = "https://github.com/SUSE/spacewalk.git"
}

variable "CUCUMBER_BRANCH" {
  type = "string"
  default = "Manager-3.2"
}

variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results 3.2-PRV $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results 3.2-PRV: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
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

variable "GIT_USER" {
  type = "string"
  default = null // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type = "string"
  default = null // Not needed for master, as it is public
}

provider "libvirt" {
  uri = "qemu+tcp://selektah.mgr.prv.suse.net/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "3.2-nightly"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["centos7o", "opensuse150o", "sles12sp3", "sles12sp4o", "ubuntu1804o"]

  use_avahi   = false
  name_prefix = "suma-32-"
  domain      = "mgr.prv.suse.net"
  from_email  = "root@suse.de"

  no_auth_registry = "minima-mirror.mgr.prv.suse.net"
  auth_registry = "minima-mirror.mgr.prv.suse.net:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_prv"

  mirror = "minima-mirror.mgr.prv.suse.net"
  use_mirror_images = true
  server_http_proxy = "galaxy-proxy.mgr.suse.de:3128"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:92:02:f0:55"
      }
    }
    server = {
      image = "sles12sp4o"
      provider_settings = {
        mac = "aa:b2:92:01:37:28"
      }
    }
    proxy = {
      image = "sles12sp4o"
      provider_settings = {
        mac = "aa:b2:92:1d:af:5a"
      }
    }
    suse-client = {
      name = "cli-sles12"
      image = "sles12sp3"
      provider_settings = {
        mac = "aa:b2:92:55:bf:9b"
      }
    }
    suse-minion = {
      name = "min-sles12"
      image = "sles12sp3"
      provider_settings = {
        mac = "aa:b2:92:e7:1e:fa"
      }
    }
    build-host = {
      image = "sles12sp3"
      provider_settings = {
        mac = "aa:b2:92:00:00:18"
      }
    }
    suse-sshminion = {
      name = "minssh-sles12"
      image = "sles12sp3"
      provider_settings = {
        mac = "aa:b2:92:99:c9:f5"
      }
    }
    redhat-minion = {
      provider_settings = {
        mac = "aa:b2:92:4f:17:48"
        memory = 3072        
      }
    }
    debian-minion = {
      provider_settings = {
        mac = "aa:b2:92:4f:17:49"
      }
    }
    pxeboot-minion = {
    }
  }
  provider_settings = {
    pool               = "ssd"
    bridge             = "br1"
    additional_network = "192.168.32.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
