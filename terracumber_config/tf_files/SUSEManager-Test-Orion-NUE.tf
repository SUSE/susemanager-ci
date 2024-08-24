// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-Test/job/manager-TEST-Orion-acceptance-tests"
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
  default = "Results TEST-ORION $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results TEST-ORION: Environment setup failed"
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
  //uri = "qemu+tcp://cthulhu.mgr.suse.de/system"
  uri = "qemu+tcp://suma-04.mgr.suse.de/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "head"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["rocky8o", "opensuse155o", "sles15sp4o", "ubuntu2204o", "slemicro55o", "leapmicro55o"]

  use_avahi    = false
  name_prefix  = "suma-testorion-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry       = "registry.mgr.suse.de"
  auth_registry          = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo      = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  container_server = true
  container_proxy  = true

  server_http_proxy        = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.suse.de:445"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:93:01:00:70"
        vcpu = 2
        memory = 2048
      }
    }
    server_containerized = {
      image = "slemicro55o"
      provider_settings = {
        mac = "aa:b2:93:01:00:71"
        vcpu = 4
        memory = 16384
      }
      login_timeout = 28800
      runtime = "podman"
      container_repository = "registry.suse.de/devel/galaxy/manager/test/orion/containerfile/suse/manager/5.0/x86_64"
      container_tag = "latest"
      additional_repos = {
        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Orion/SLE_15_SP5/"
      }
    }
    proxy_containerized = {
      image = "slemicro55o"
      provider_settings = {
        mac = "aa:b2:93:01:00:72"
        vcpu = 2
        memory = 2048
      }
      main_disk_size = 200
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
      runtime = "podman"
      container_repository = "registry.suse.de/devel/galaxy/manager/test/orion/containerfile/suse/manager/5.0/x86_64"
      container_tag = "latest"
      additional_repos = {
        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Orion/SLE_15_SP5/"
      }
    }
    suse-minion = {
      image = "sles15sp4o"
      name = "min-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:76"
        vcpu = 2
        memory = 2048
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = "sles15sp4o"
      name = "minssh-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:78"
        vcpu = 2
        memory = 2048
      }
      additional_packages = [ "venv-salt-minion", "iptables" ]
      install_salt_bundle = true
    }
    redhat-minion = {
      image = "rocky8o"
      name = "min-rocky8"
      provider_settings = {
        mac = "aa:b2:93:01:00:79"
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Also, openscap cannot run with less than 1.25 GB of RAM
        vcpu = 2
        memory = 2048
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    debian-minion = {
      image = "ubuntu2204o"
      name = "min-ubuntu2204"
      provider_settings = {
        mac = "aa:b2:93:01:00:7b"
        vcpu = 2
        memory = 2048
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    build-host = {
      image = "sles15sp4o"
      name = "min-build"
      provider_settings = {
        mac = "aa:b2:93:01:00:7d"
        vcpu = 2
        memory = 2048
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    pxeboot-minion = {
      image = "sles15sp4o"
    }
    kvm-host = {
      image = "sles15sp4o"
      name = "min-kvm"
      provider_settings = {
        mac = "aa:b2:93:01:00:7c"
        vcpu = 4
        memory = 4096
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
  }

  provider_settings = {
    pool = "ssd"
    network_name = null
    bridge = "br0"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
