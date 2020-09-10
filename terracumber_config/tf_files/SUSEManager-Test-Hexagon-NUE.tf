// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Manager-Test/job/manager-TEST-Hexagon-cucumber"
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
  default = "Manager-4.1"
}

variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results TEST-HEXAGON $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results TEST-HEXAGON: Environment setup failed"
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
  uri = "qemu+tcp://cthulu.mgr.suse.de/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "uyuni-released"
  
  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["centos7", "opensuse150", "opensuse151", "opensuse152o", "sles15sp1", "sles15sp2o", "ubuntu1804"]

  use_avahi    = false
  name_prefix  = "suma-testhexagon-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  portus_uri = "portus.mgr.suse.de:5000/cucutest"
  portus_username = "cucutest"
  portus_password = "cucusecret"

  server_http_proxy = "galaxy-proxy.mgr.suse.de:3128"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "AA:B2:93:00:00:B4"
      }
    }
    server = {
      provider_settings = {
        mac = "AA:B2:93:00:00:B0"
      }
      additional_repos = {
        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Hexagon/openSUSE_Leap_15.2/"
      }
    }
    proxy = {
      provider_settings = {
        mac = "AA:B2:93:00:00:B6"
      }
      additional_repos = {
        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Hexagon/openSUSE_Leap_15.2/"
      }
    }
    suse-client = {
      image = "sles15sp1"
      name = "cli-sles15"
      provider_settings = {
        mac = "AA:B2:93:00:00:B1"
      }
    }
    suse-minion = {
      image = "sles15sp1"
      name = "min-sles15"
      provider_settings = {
        mac = "AA:B2:93:00:00:B3"
      }
    }
  }
  provider_settings = {
    pool         = "ssd"
    network_name = null
    bridge       = "br0"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
