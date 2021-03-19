// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Manager-4.1/job/manager-4.1-cucumber-NUE"
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
  default = "Results 4.1-NUE (backup and staging) $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins-backup.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results 4.1-NUE: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins-backupenv-fail.txt"
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

  product_version = "4.1-nightly"
  
  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["centos7o", "opensuse152o", "sles15sp1o", "sles15sp2o", "ubuntu2004o"]

  use_avahi    = false
  name_prefix  = "suma-41-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry = "registry.mgr.suse.de"
  auth_registry = "portus.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  server_http_proxy = "galaxy-proxy.mgr.suse.de:3128"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:93:01:00:a0"
      }
    }
    server = {
      provider_settings = {
        mac = "aa:b2:93:01:00:a1"
      }
    }
    proxy = {
      provider_settings = {
        mac = "aa:b2:93:01:00:a2"
      }
    }
    suse-client = {
      image = "sles15sp1o"
      name = "cli-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:a4"
      }
    }
    suse-minion = {
      image = "sles15sp1o"
      name = "min-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:a6"
      }
    }
    suse-sshminion = {
      image = "sles15sp1o"
      name = "minssh-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:a8"
      }
    }
    redhat-minion = {
      image = "centos7o"
      provider_settings = {
        mac = "aa:b2:93:01:00:a9"
        // Openscap cannot run with less than 1.25 GB of RAM
        memory = 1280
      }
    }
    debian-minion = {
      name = "min-ubuntu2004"
      image = "ubuntu2004o"
      provider_settings = {
        mac = "aa:b2:93:01:00:ac"
      }
    }
    build-host = {
      image = "sles15sp2o"
      provider_settings = {
        mac = "aa:b2:93:01:00:ad"
      }
    }
    pxeboot-minion = {
      image = "sles15sp2o"
    }
    kvm-host = {
      image = "sles15sp2o"
      provider_settings = {
        mac = "aa:b2:93:01:00:ae"
      }
    }
    xen-host = {
      image = "sles15sp2o"
      provider_settings = {
        mac = "aa:b2:93:01:00:af"
      }
    }
  }
  provider_settings = {
    pool = "ssd"
    network_name = null
    bridge = "br0"
    additional_network = "192.168.41.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
