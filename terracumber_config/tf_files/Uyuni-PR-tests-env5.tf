// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-prs-ci-tests"
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
  default = "Results Uyuni Pull Request $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results Pull Request: Environment setup failed"
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

// Repository containing the build for the tested Uyuni Pull Request
variable "PULL_REQUEST_REPO" {
  type = "string"
}

variable "MASTER_REPO" {
  type = "string"
}

provider "libvirt" {
  uri = "qemu+tcp://hyperion.mgr.prv.suse.net/system"
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

  images = ["centos7o", "opensuse152o", "opensuse153o", "opensuse153-ci-pr", "sles15sp1o", "sles15sp3o", "ubuntu2004o"]

  use_avahi    = false
  name_prefix  = "suma-pr5-"
  domain       = "mgr.prv.suse.net"
  from_email   = "root@suse.de"

  no_auth_registry = "registry.mgr.suse.de"
  auth_registry      = "portus.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  server_http_proxy = "galaxy-proxy.mgr.suse.de:3128"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:92:04:00:30"
      }
    }
    server = {
      provider_settings = {
        mac = "aa:b2:92:04:00:31"
      }
      additional_repos = {
        pull_request_repo = var.PULL_REQUEST_REPO,
        master_repo = var.MASTER_REPO,
      }
      image = "opensuse153-ci-pr"
    }
    proxy = {
      provider_settings = {
        mac = "aa:b2:92:04:00:32"
      }
      additional_repos = {
        pull_request_repo = var.PULL_REQUEST_REPO,
        master_repo = var.MASTER_REPO,
      }
    }
    suse-client = {
      image = "sles15sp1o"
      name = "cli-sles15"
      provider_settings = {
        mac = "aa:b2:92:04:00:33"
      }
    }
    suse-minion = {
      image = "sles15sp1o"
      name = "min-sles15"
      provider_settings = {
        mac = "aa:b2:92:04:00:34"
      }
    }
    suse-sshminion = {
      image = "sles15sp1o"
      name = "minssh-sles15"
      provider_settings = {
        mac = "aa:b2:92:04:00:35"
      }
    }
    redhat-minion = {
      image = "centos7o"
      provider_settings = {
        mac = "aa:b2:92:04:00:36"
        memory = 2048
        vcpu = 2
      }
    }
    debian-minion = {
      name = "min-ubuntu2004"
      image = "ubuntu2004o"
      provider_settings = {
        mac = "aa:b2:92:04:00:38"
      }
    }
    build-host = {
      image = "sles15sp3o"
      provider_settings = {
        mac = "aa:b2:92:04:00:39"
      }
    }
    pxeboot-minion = {
      image = "sles15sp3o"
    }
    kvm-host = {
      image = "opensuse153o"
      provider_settings = {
        mac = "aa:b2:92:04:00:3a"
      }
    }
    xen-host = {
      image = "opensuse153o"
      provider_settings = {
        mac = "aa:b2:92:04:00:3b"
      }
    }
  }
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br1"
    additional_network = "192.168.105.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
