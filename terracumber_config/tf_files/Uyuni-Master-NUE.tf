// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-master-cucumber-NUE"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = "string"
  default = "export PRODUCT='Uyuni' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = "string"
  default = "https://github.com/uyuni-project/uyuni.git"
}

variable "CUCUMBER_BRANCH" {
  type = "string"
  default = "master"
}

variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results Uyuni-Master $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results Uyuni-Master: Environment setup failed"
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
  uri = "qemu+tcp://ramrod.mgr.suse.de/system"
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

  images = ["centos7o", "opensuse150o", "opensuse151o", "opensuse152o", "sles15sp1o", "sles15sp2o", "ubuntu1804o"]

  use_avahi    = false
  name_prefix  = "uyuni-master-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  portus_uri      = "portus.mgr.suse.de:5000/cucutest"
  portus_username = "cucutest"
  portus_password = "cucusecret"

  server_http_proxy = "galaxy-proxy.mgr.suse.de:3128"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "AA:B2:93:00:00:05"
      }
    }
    server = {
      provider_settings = {
        mac = "AA:B2:93:00:00:00"
      }
    }
    proxy = {
      provider_settings = {
        mac = "AA:B2:93:00:00:06"
      }
    }
    suse-client = {
      image = "sles15sp1"
      name = "cli-sles15"
      provider_settings = {
        mac = "AA:B2:93:00:00:01"
      }
    }
    suse-minion = {
      image = "sles15sp1"
      name = "min-sles15"
      provider_settings = {
        mac = "AA:B2:93:00:00:02"
      }
    }
    build-host = {
      image = "sles15sp2o"
      provider_settings = {
        mac = "AA:B2:93:00:00:09"
      }
    }
    suse-sshminion = {
      image = "sles15sp1"
      name = "minssh-sles15"
      provider_settings = {
        mac = "AA:B2:93:00:00:03"
      }
    }
    redhat-minion = {
      provider_settings = {
        mac = "AA:B2:93:00:00:04"
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Still researching, but it will do it for now
        memory = 2048
        vcpu = 2
      }
    }
    debian-minion = {
      provider_settings = {
        mac = "AA:B2:93:00:00:08"
      }
    }
    pxeboot-minion = {
      image = "sles15sp2o"
    }
    kvm-host = {
      image = "opensuse152o"
      provider_settings = {
        mac = "AA:B2:93:00:00:07"
      }
    }
  }
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br0"
    additional_network = "192.168.100.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
