// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-4.2/job/manager-4.2-dev-acceptance-tests-PRV"
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
  default = "Results 4.2-PRV $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results 4.2-PRV: Environment setup failed"
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

  product_version = "4.2-nightly"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["centos7o", "opensuse152o", "sles15sp2o", "sles15sp3o", "ubuntu2004o"]

  use_avahi = false
  name_prefix = "suma-42-"
  domain = "mgr.prv.suse.net"
  from_email = "root@suse.de"

  no_auth_registry = "registry.mgr.prv.suse.net"
  auth_registry = "registry.mgr.prv.suse.net:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_prv"

  mirror = "minima-mirror.mgr.prv.suse.net"
  use_mirror_images = true
  server_http_proxy = "galaxy-proxy.mgr.prv.suse.net:3128"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:92:03:00:c0"
      }
    }
    server = {
      additional_repos = { cobbler = "http://download.suse.de/ibs/SUSE:/Maintenance:/22865/SUSE_Updates_SLE-Module-SUSE-Manager-Server_4.2_x86_64/" }
      provider_settings = {
        mac = "aa:b2:92:03:00:c1"
      }
    }
    proxy = {
      provider_settings = {
        mac = "aa:b2:92:03:00:c2"
      }
    }
    suse-client = {
      image = "sles15sp2o"
      name = "cli-sles15"
      provider_settings = {
        mac = "aa:b2:92:03:00:c4"
      }
    }
    suse-minion = {
      image = "sles15sp2o"
      name = "min-sles15"
      provider_settings = {
        mac = "aa:b2:92:03:00:c6"
      }
    }
    suse-sshminion = {
      image = "sles15sp2o"
      name = "minssh-sles15"
      provider_settings = {
        mac = "aa:b2:92:03:00:c8"
      }
    }
    redhat-minion = {
      image = "centos7o"
      provider_settings = {
        mac = "aa:b2:92:03:00:c9"
        // Openscap cannot run with less than 1.25 GB of RAM
        memory = 1280
      }
    }
    debian-minion = {
      name = "min-ubuntu2004"
      image = "ubuntu2004o"
      provider_settings = {
        mac = "aa:b2:92:03:00:cc"
      }
    }
    build-host = {
      image = "sles15sp2o"
      provider_settings = {
        mac = "aa:b2:92:03:00:cd"
      }
    }
    pxeboot-minion = {
      image = "sles15sp3o"
    }
    kvm-host = {
      image = "sles15sp3o"
      additional_grains = {
        hvm_disk_image = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.3/appliances/openSUSE-Leap-15.3-JeOS.x86_64-OpenStack-Cloud.qcow2"
        hvm_disk_image_hash = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.3/appliances/openSUSE-Leap-15.3-JeOS.x86_64-OpenStack-Cloud.qcow2.sha256"
      }
      provider_settings = {
        mac = "aa:b2:92:03:00:ce"
      }
    }
    xen-host = {
      image = "sles15sp3o"
      additional_grains = {
        xen_disk_image = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.3/appliances/openSUSE-Leap-15.3-JeOS.x86_64-15.3-kvm-and-xen-Current.qcow2"
        xen_disk_image_hash = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.3/appliances/openSUSE-Leap-15.3-JeOS.x86_64-15.3-kvm-and-xen-Current.qcow2.sha256"
        hvm_disk_image = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.3/appliances/openSUSE-Leap-15.3-JeOS.x86_64-OpenStack-Cloud.qcow2"
        hvm_disk_image_hash = "http://minima-mirror.mgr.prv.suse.net/distribution/leap/15.3/appliances/openSUSE-Leap-15.3-JeOS.x86_64-OpenStack-Cloud.qcow2.sha256"
      }
      provider_settings = {
        mac = "aa:b2:92:03:00:cf"
      }
    }
  }
  provider_settings = {
    pool = "ssd"
    network_name = null
    bridge = "br1"
    additional_network = "192.168.42.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
