// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Manager-4.0/job/manager-4.0-cucumber-PRV"
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
  default = "Manager-4.0"
}

variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results 4.0-PRV $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results 4.0-PRV: Environment setup failed"
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
  uri = "qemu+tcp://metropolis.prv.suse.net/system"
}


module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "4.0-nightly"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  
  images = ["centos7", "opensuse150", "sles15sp1", "sles15sp2", "ubuntu1804"]

  use_avahi = false
  name_prefix = "suma-40-"
  domain = "prv.suse.net"
  from_email = "root@suse.de"

  portus_uri = "portus.mgr.suse.de:5000/cucutest"
  portus_username = "cucutest"
  portus_password = "cucusecret"

  mirror = "minima-mirror.prv.suse.net"
  use_mirror_images = true
  server_http_proxy = "galaxy-proxy.mgr.suse.de:3128"

  host_settings = {
    ctl = {
      provider_settings = {
        mac = "52:54:00:00:00:06"
      }
    }
    srv = {
      provider_settings = {
        mac = "52:54:00:00:00:01"
      }
    }
    pxy = {
      provider_settings = {
        mac = "52:54:00:00:00:07"
      }
    }
    cli-sles12sp4 = {
      image = "sles15sp1"
      name = "cli-sles15"
      provider_settings = {
        mac = "52:54:00:00:00:02"
      }
    }
    min-sles12sp4 = {
      image = "sles15sp1"
      name = "min-sles15"
      provider_settings = {
        mac = "52:54:00:00:00:03"
      }
    }
    min-build = {
      image = "sles15sp1"
      provider_settings = {
        mac = "52:54:00:00:00:20"
      }
    }
    minssh-sles12sp4 = {
      image = "sles15sp1"
      name = "minssh-sles15"
      provider_settings = {
        mac = "52:54:00:00:00:04"
      }
    }
    min-centos7 = {
      provider_settings = {
        mac = "52:54:00:00:00:05"
      }
    }
    min-ubuntu1804 = {
      provider_settings = {
        mac = "52:54:00:00:00:08"
      }
    }
    min-pxeboot = {
      present = true
      image = "sles15sp1"
    }
    min-kvm = {
      image = "sles15sp1"
      provider_settings = {
        mac = "52:54:00:00:00:09"
      }
    }
  }
  provider_settings = {
    pool = "ssd"
    network_name = null
    bridge = "br0"
    additional_network = "192.168.40.0/24"
  }
}
  
output "configuration" {
  value = module.cucumber_testsuite.configuration
}
