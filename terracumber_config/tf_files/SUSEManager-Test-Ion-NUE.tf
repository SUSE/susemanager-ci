// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-Test/job/manager-TEST-Ion-acceptance-tests"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
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
  default = "Results TEST-ION $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results TEST-ION: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = string
  default = "jenkins@suse.de"
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
  uri = "qemu+tcp://suma-04.mgr.suse.de/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "5.0-released"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["rocky8o", "opensuse155o", "ubuntu2404o", "sles15sp4o", "slemicro55o"]

  use_avahi    = false
  name_prefix  = "suma-test-ion-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry       = "registry.mgr.suse.de"
  auth_registry          = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo      = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  server_http_proxy = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.suse.de:445"

  container_server = true
  container_proxy = true

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:93:01:00:40"
      }
    }
    server_containerized = {
      provider_settings = {
        mac = "aa:b2:93:01:00:41"
        vcpu = 8
        memory = 32768
      }
      main_disk_size = 500
      login_timeout = 28800
      runtime = "podman"
      container_repository = "registry.suse.de/devel/galaxy/manager/test/ion/containerfile"
      container_tag = "latest"
      beta_enabled = false
    }
    proxy_containerized = {
      provider_settings = {
        mac = "aa:b2:93:01:00:42"
        vcpu = 2
        memory = 2048
      }
    }
    slemicro_minion = {
      provider_settings = {
        mac = "aa:b2:93:01:00:44"
        vcpu = 2
        memory = 2048
      }
    }
    suse_minion = {
      image = "sles15sp4o"
      provider_settings = {
        mac = "aa:b2:93:01:00:46"
        vcpu = 2
        memory = 2048
      }
    }
    suse_sshminion = {
      image = "sles15sp4o"
      provider_settings = {
        mac = "aa:b2:93:01:00:48"
        vcpu = 2
        memory = 2048
      }
    }
    rhlike_minion = {
      image = "rocky8o"
      provider_settings = {
        mac = "aa:b2:93:01:00:49"
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Also, openscap cannot run with less than 1.25 GB of RAM
        vcpu = 2
        memory = 2048
      }
    }
    deblike_minion = {
      image = "ubuntu2404o"
      provider_settings = {
        mac = "aa:b2:93:01:00:4b"
        vcpu = 2
        memory = 2048
      }
    }
    build_host = {
      image = "sles15sp4o"
      provider_settings = {
        mac = "aa:b2:93:01:00:4d"
        vcpu = 2
        memory = 2048
      }
    }
    pxeboot_minion = {
      image = "sles15sp4o"
    }
    kvm_host = {
      image = "sles15sp4o"
      provider_settings = {
        mac = "aa:b2:93:01:00:4e"
      }
    }
  }
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br0"
    additional_network = "192.168.41.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
