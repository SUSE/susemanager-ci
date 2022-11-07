// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-4.3/job/manager-4.3-dev-acceptance-tests-PRV"
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
  default = "Manager-4.3"
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "Results 4.3-PRV $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results 4.3-PRV: Environment setup failed"
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
  uri = "qemu+tcp://metropolis.mgr.prv.suse.net/system"
}


module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "4.3-nightly"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["centos7o", "opensuse154o", "sles15sp4o", "ubuntu2204o"]

  use_avahi = false
  name_prefix = "suma-43-"
  domain = "mgr.prv.suse.net"
  from_email = "root@suse.de"

  no_auth_registry = "registry.mgr.prv.suse.net"
  auth_registry = "registry.mgr.prv.suse.net:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_prv"

  mirror = "minima-mirror.mgr.prv.suse.net"
  use_mirror_images = true
  server_http_proxy = "http-proxy.mgr.prv.suse.net:3128"
  custom_download_endpoint = "ftp://minima-mirror.mgr.prv.suse.net:445"

  # when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:92:03:00:80"
      }
    }
    server = {
      provider_settings = {
        mac = "aa:b2:92:03:00:81"
      }
    }
    proxy = {
      provider_settings = {
        mac = "aa:b2:92:03:00:82"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-client = {
      image = "sles15sp4o"
      name = "cli-sles15"
      provider_settings = {
        mac = "aa:b2:92:03:00:84"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-minion = {
      image = "sles15sp4o"
      name = "min-sles15"
      provider_settings = {
        mac = "aa:b2:92:03:00:86"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = "sles15sp4o"
      name = "minssh-sles15"
      provider_settings = {
        mac = "aa:b2:92:03:00:88"
      }
      additional_packages = [ "venv-salt-minion", "iptables" ]
      install_salt_bundle = true
    }
    redhat-minion = {
      image = "centos7o"
      name = "min-centos7"
      provider_settings = {
        mac = "aa:b2:92:03:00:89"
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Also, openscap cannot run with less than 1.25 GB of RAM
        memory = 2048
        vcpu = 2
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    debian-minion = {
      image = "ubuntu2204o"
      name = "min-ubuntu2204"
      provider_settings = {
        mac = "aa:b2:92:03:00:8b"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    build-host = {
      image = "sles15sp4o"
      provider_settings = {
        mac = "aa:b2:92:03:00:8d"
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
      additional_grains = {
        hvm_disk_image = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.4/appliances/openSUSE-Leap-15.4-JeOS.x86_64-OpenStack-Cloud.qcow2"
        hvm_disk_image_hash = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.4/appliances/openSUSE-Leap-15.4-JeOS.x86_64-OpenStack-Cloud.qcow2.sha256"
      }
      provider_settings = {
        mac = "aa:b2:92:03:00:8e"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
  }
  provider_settings = {
    pool = "ssd"
    network_name = null
    bridge = "br1"
    additional_network = "192.168.43.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
