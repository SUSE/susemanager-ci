// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-master-dev-acceptance-tests-NUE"
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
  default = "Results Uyuni-Master $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Uyuni-Master: Environment setup failed"
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
  uri = "qemu+tcp://mortadelo.mgr.suse.de/system"
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

  images = ["centos7o", "opensuse152o", "opensuse153o", "sles15sp2o", "sles15sp3o", "ubuntu2004o"]

  use_avahi    = false
  name_prefix  = "uyuni-master-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry = "registry.mgr.suse.de"
  auth_registry      = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  server_http_proxy = "http-proxy.mgr.suse.de:3128"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:93:01:00:d0"
      }
    }
    server = {
      provider_settings = {
        mac = "aa:b2:93:01:00:d1"
        memory = 10240
      }
    }
    proxy = {
      provider_settings = {
        mac = "aa:b2:93:01:00:d2"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-client = {
      image = "sles15sp2o"
      name = "cli-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:d4"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-minion = {
      image = "sles15sp2o"
      name = "min-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:d6"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = "sles15sp2o"
      name = "minssh-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:d8"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    redhat-minion = {
      image = "centos7o"
      provider_settings = {
        mac = "aa:b2:93:01:00:d9"
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Also, openscap cannot run with less than 1.25 GB of RAM
        memory = 2048
        vcpu = 2
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    debian-minion = {
      name = "min-ubuntu2004"
      image = "ubuntu2004o"
      provider_settings = {
        mac = "aa:b2:93:01:00:dc"
      }
      additional_packages = [ "venv-salt-minion" ]

      // FIXME: cloudl-init fails if venv-salt-minion is not avaiable
      // We can set "install_salt_bundle = true" as soon as venv-salt-minion is available Uyuni:Stable
      install_salt_bundle = false
    }
    build-host = {
      image = "sles15sp3o"
      provider_settings = {
        mac = "aa:b2:93:01:00:dd"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    pxeboot-minion = {
      image = "sles15sp3o"
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    kvm-host = {
      image = "opensuse153o"
      provider_settings = {
        mac = "aa:b2:93:01:00:de"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    xen-host = {
      image = "opensuse153o"
      provider_settings = {
        mac = "aa:b2:93:01:00:df"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
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
