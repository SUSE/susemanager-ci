// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-5.0/job/manager-5.0-dev-acceptance-tests-SLC"
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
  default = "Manager-5.0"
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "Results 5.0-SLC $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results 5.0-SLC: Environment setup failed"
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
  required_version = ">= 1.6.0"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://selektah.mgr.slc1.suse.org/system"
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

  images = ["rocky8o", "opensuse156o", "ubuntu2404o", "sles15sp7o", "slemicro55o"]

  use_avahi    = false
  name_prefix  = "suma-ci-50-"
  domain       = "mgr.slc1.suse.org"
  from_email   = "root@suse.de"

  no_auth_registry       = "registry.mgr.slc1.suse.org"
  auth_registry          = "registry.mgr.slc1.suse.org:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo      = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/temporary"

  container_server = true
  container_proxy  = true

  mirror                   = "minima-mirror-ci-bv.mgr.slc1.suse.org"
  use_mirror_images        = true

  server_http_proxy        = "http-proxy.mgr.slc1.suse.org:3128"
  custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.slc1.suse.org:445"

  # when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:92:03:00:a0"
        vcpu = 4
        memory = 4096
      }
    }
    server_containerized = {
      image = "slemicro55o"
      provider_settings = {
        mac = "aa:b2:92:03:00:a1"
        vcpu = 8
        memory = 32768
      }
      main_disk_size       = 500
      login_timeout        = 28800
      large_deployment     = true
      runtime              = "podman"
      container_repository = "registry.suse.de"
      container_tag        = "latest"
    }
    proxy_containerized = {
      image = "slemicro55o"
      provider_settings = {
        mac = "aa:b2:92:03:00:a2"
        vcpu = 2
        memory = 2048
      }
      main_disk_size = 200
      runtime = "podman"
      container_repository = "registry.suse.de"
      container_tag = "latest"
    }
    suse_minion = {
      image = "sles15sp7o"
      provider_settings = {
        mac = "aa:b2:92:03:00:a6"
        vcpu = 2
        memory = 2048
      }
    }
    suse_sshminion = {
      image = "sles15sp7o"
      provider_settings = {
        mac = "aa:b2:92:03:00:a8"
        vcpu = 2
        memory = 2048
      }
    }
    rhlike_minion = {
      image = "rocky8o"
      provider_settings = {
        mac = "aa:b2:92:03:00:aa"
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Also, openscap cannot run with less than 1.25 GB of RAM
        vcpu = 2
        memory = 2048
      }
    }
    deblike_minion = {
      image = "ubuntu2404o"
      provider_settings = {
        mac = "aa:b2:92:03:00:ab"
        vcpu = 2
        memory = 2048
      }
    }
    build_host = {
      image = "sles15sp7o"
      provider_settings = {
        mac = "aa:b2:92:03:00:ad"
        vcpu = 2
        memory = 2048
      }
    }
    pxeboot_minion = {
      image = "sles15sp7o"
    }
    dhcp_dns = {
      name = "dhcp-dns"
      image = "opensuse156o"
      hypervisor = {
        host        = "selektah.mgr.slc1.suse.org"
        user        = "root"
        private_key = file("~/.ssh/id_ed25519")
      }
    }
    kvm_host = {
      image = "sles15sp7o"
      provider_settings = {
        mac = "aa:b2:92:03:00:ae"
        vcpu = 4
        memory = 4096
      }
    }
  }

  provider_settings = {
    pool = "ssd"
    network_name = null
    bridge = "br1"
    additional_network = "192.168.50.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
