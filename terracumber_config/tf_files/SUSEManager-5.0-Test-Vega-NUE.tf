// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-Test/job/manager-TEST-Vega-acceptance-tests"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='Uyuni' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = string
  default = "https://github.com/SUSE/spacewalk.git"
}

variable "CUCUMBER_BRANCH" {
  type = string
  default = "Manager-5.0"
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "Results TEST-VEGA $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results TEST-VEGA: Environment setup failed"
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

variable "SCC_PTF_USER" {
  type = string
  default = null
  // Not needed for master, as PTFs are only build for SUSE Manager / MLM
}

variable "SCC_PTF_PASSWORD" {
  type = string
  default = null
  // Not needed for master, as PTFs are only build for SUSE Manager / MLM
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
      version = "0.8.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://cthulhu.mgr.suse.de/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "5.0-nightly"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  cc_ptf_username = var.SCC_PTF_USER
  cc_ptf_password = var.SCC_PTF_PASSWORD

  images = ["rocky8o", "opensuse155o", "opensuse156o", "ubuntu2404o", "sles15sp4o", "slemicro55o"]

  use_avahi    = false
  name_prefix  = "suma-test-vega-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry = "registry.mgr.suse.de"
  auth_registry = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  container_server = true
  container_proxy = true

  mirror                   = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images        = true

  # server_http_proxy = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.suse.de:445"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:93:01:00:30"
      }
    }
    server_containerized = {
      provider_settings = {
        mac = "aa:b2:93:01:00:31"
        vcpu = 8
        memory = 32768
      }
      main_disk_size = 500
      login_timeout = 28800
      runtime = "podman"
      container_repository = "registry.suse.de/devel/galaxy/manager/5.0/containerfile"
      container_tag = "latest"
    }
    proxy_containerized = {
      provider_settings = {
        mac = "aa:b2:93:01:00:32"
        vcpu = 2
        memory = 2048
      }
      main_disk_size = 200
      runtime = "podman"
      container_repository = "registry.suse.de/devel/galaxy/manager/5.0/containerfile"
      container_tag = "latest"
    }
    suse_minion = {
      image = "sles15sp4o"
      provider_settings = {
        mac = "aa:b2:93:01:00:36"
      }
    }
    build_host = {
      image = "sles15sp4o"
      provider_settings = {
        mac = "aa:b2:93:01:00:3d"
        memory = 2048
      }
    }
    dhcp_dns = {
      name        = "dhcp-dns"
      image       = "opensuse155o"
      hypervisor  = {
        host        = "cthulhu.mgr.suse.de"
        user        = "root"
        private_key = file("~/.ssh/id_ed25519")
      }
    }
  }
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br0"
    additional_network = "192.168.77.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
