// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-4.2/job/manager-4.2-dev-acceptance-tests-NUE"
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
  default = "Manager-4.2"
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "Results 4.2-NUE (backup and staging) $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins-backup.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results 4.2-NUE: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-backupenv-fail.txt"
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
  uri = "qemu+tcp://suma-01.mgr.suse.de/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "4.2-nightly"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["centos7o", "opensuse154o", "sles15sp3o", "ubuntu2004o"]

  use_avahi    = false
  name_prefix  = "suma-42-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry = "registry.mgr.suse.de"
  auth_registry = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  server_http_proxy = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint = "ftp://minima-mirror.mgr.suse.de:445"

  # when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:93:01:00:80"
        vcpu = 2
        memory = 2048
      }
    }
    server = {
      provider_settings = {
        mac = "aa:b2:93:01:00:81"
        vcpu = 4
        memory = 16384
      }
    }
    proxy = {
      provider_settings = {
        mac = "aa:b2:93:01:00:82"
        vcpu = 2
        memory = 2048
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-client = {
      image = "sles15sp3o"
      name = "cli-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:84"
        vcpu = 2
        memory = 2048
      }
    }
    suse-minion = {
      image = "sles15sp3o"
      name = "min-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:86"
        vcpu = 2
        memory = 2048
      }
    }
    suse-sshminion = {
      image = "sles15sp3o"
      name = "minssh-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:88"
        vcpu = 2
        memory = 2048
      }
    }
    redhat-minion = {
      image = "centos7o"
      name = "min-centos7"
      provider_settings = {
        mac = "aa:b2:93:01:00:89"
        // Openscap cannot run with less than 1.25 GB of RAM
        vcpu = 2
        memory = 2048
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    debian-minion = {
      name = "min-ubuntu2004"
      image = "ubuntu2004o"
      provider_settings = {
        mac = "aa:b2:93:01:00:8c"
        vcpu = 2
        memory = 2048
      }
    }
    build-host = {
      image = "sles15sp3o"
      name = "min-build"
      provider_settings = {
        mac = "aa:b2:93:01:00:8d"
        vcpu = 2
        memory = 2048
      }
    }
    pxeboot-minion = {
      image = "sles15sp3o"
      provider_settings = {
        vcpu = 2
        memory = 2048
      }
    }
    kvm-host = {
      image = "sles15sp3o"
      name = "min-kvm"
      provider_settings = {
        mac = "aa:b2:93:01:00:8e"
        vcpu = 4
        memory = 4096
      }
    }
  }
  nested_vm_host = "min-nested"
  provider_settings = {
    pool = "ssd"
    network_name = null
    bridge = "br0"
    additional_network = "192.168.42.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
