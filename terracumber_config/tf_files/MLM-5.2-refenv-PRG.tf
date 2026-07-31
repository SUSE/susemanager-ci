// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://jenkins.mgr.suse.de/job/manager-5.2-infra-reference"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

// Not really used in this pipeline, as we do not run cucumber
variable "CUCUMBER_GITREPO" {
  type = string
  default = "https://github.com/SUSE/spacewalk.git"
}

// Not really used in this pipeline, as we do not run cucumber
variable "CUCUMBER_BRANCH" {
  type = string
  default = "Manager-5.2"
}

// Not really used in this pipeline, as we do not run cucumber
variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

// Not really used in this pipeline, as we do not send emails on success (no cucumber results)
variable "MAIL_SUBJECT" {
  type = string
  default = "Results REF5.2-PRG $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results REF5.2-PRG: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-refenv-fail.txt"
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

// Both paths are written to terraform.tfvars by the pipeline when running on
// jenkins.mgr.suse.de, where the keys live in the agent home instead of sumaform
variable "CONTROLLER_PUBLIC_SSH_KEY_PATH" {
  type = string
  default = "./salt/controller/id_ed25519.pub"
}

variable "HYPERVISOR_PRIVATE_SSH_KEY_PATH" {
  type = string
  default = "~/.ssh/id_ed25519"
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
  uri = "qemu+tcp://suma-02.mgr.suse.de/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "5.2-nightly"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  cc_ptf_username = var.SCC_PTF_USER
  cc_ptf_password = var.SCC_PTF_PASSWORD

  ssh_key_path = var.CONTROLLER_PUBLIC_SSH_KEY_PATH

  images = ["rocky10o", "opensuse156o", "opensuse160o", "ubuntu2404o", "sles15sp7o", "slmicro62o"]

  use_avahi    = false
  name_prefix  = "mlm-ref-52-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry       = "registry.mgr.suse.de"
  auth_registry          = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo      = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/temporary"

  container_server = true
  container_proxy  = true

  # server_http_proxy        = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.suse.de:445"

  # when changing images, please also keep in mind to adjust the image matrix in the "Used image versions" section of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:93:01:02:f0"
        vcpu = 2
        memory = 2048
      }
    }
    server_containerized = {
      image = "slmicro62o"
      provider_settings = {
        mac = "aa:b2:93:01:02:f1"
        vcpu = 4
        memory = 16384
      }
      main_disk_size = 500
      login_timeout = 28800
      runtime = "podman"
      container_registry = "registry.suse.de"
      container_tag = "latest"
    }
    proxy_containerized = {
      image = "slmicro62o"
      provider_settings = {
        mac = "aa:b2:93:01:02:f2"
        vcpu = 2
        memory = 2048
      }
      main_disk_size = 200
      runtime = "podman"
      container_registry = "registry.suse.de"
      container_tag = "latest"
    }
    suse_minion = {
      image = "sles15sp7o"
      provider_settings = {
        mac = "aa:b2:93:01:02:f6"
        vcpu = 2
        memory = 2048
      }
    }
    suse_sshminion = {
      image = "sles15sp7o"
      provider_settings = {
        mac = "aa:b2:93:01:02:f8"
        vcpu = 2
        memory = 2048
      }
    }
    rhlike_minion = {
      image = "rocky10o"
      provider_settings = {
        mac = "aa:b2:93:01:02:f9"
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Also, openscap cannot run with less than 1.25 GB of RAM
        vcpu = 2
        memory = 2048
      }
    }
    deblike_minion = {
      image = "ubuntu2404o"
      provider_settings = {
        mac = "aa:b2:93:01:02:fb"
        vcpu = 2
        memory = 2048
      }
    }
    build_host = {
      image = "sles15sp7o"
      provider_settings = {
        mac = "aa:b2:93:01:02:fd"
        vcpu = 2
        memory = 2048
      }
    }
  }
  provider_settings = {
    pool = "ssd"
    network_name = null
    bridge = "br1"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
