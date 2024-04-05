// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/suma43-prs-ci-tests"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = string
  default = "https://github.com/SUSE/spacewalk/spacewalk.git"
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
  default = "$status acceptance tests on SUMA 4.3 Pull Request: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins-suma43-pull-request.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Failed acceptance tests on Pull Request: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-suma43-pull-request-env-fail.txt"
}

variable "ENVIRONMENT" {
  type = string
  default = "5"
}

variable "HYPER" {
  type = string
  default = "hyperion.mgr.prv.suse.net"
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

// Repository containing the build for the tested Uyuni Pull Request
variable "PULL_REQUEST_REPO" {
  type = string
}

variable "MASTER_REPO" {
  type = string
}

variable "MASTER_OTHER_REPO" {
  type = string
}

variable "MASTER_SUMAFORM_TOOLS_REPO" {
  type = string
}

variable "UPDATE_REPO" {
  type = string
}

variable "ADDITIONAL_REPO_URL" {
  type = string
}

variable "TEST_PACKAGES_REPO" {
  type = string
}

// Repositories containing the client tools RPMs
variable "SLE_CLIENT_REPO" {
  type = string
}

variable "RHLIKE_CLIENT_REPO" {
  type = string
}

variable "DEBLIKE_CLIENT_REPO" {
  type = string
}

variable "OPENSUSE_CLIENT_REPO" {
  type = string
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
  uri = "qemu+tcp://${var.HYPER}/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "4.3-pr"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  mirror      = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  images = ["rocky9o", "opensuse155o", "sles15sp4o", "ubuntu2204o"]

  use_avahi    = false
  name_prefix  = "suma-pr${var.ENVIRONMENT}-"
  domain       = "mgr.prv.suse.net"
  from_email   = "root@suse.de"

  no_auth_registry = "registry.mgr.prv.suse.net"
  auth_registry      = "registry.mgr.prv.suse.net:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git//:testsuite/features/profiles/internal_prv"

  server_http_proxy = "http-proxy.mgr.prv.suse.net:3128"
  custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.prv.suse.net:445"

  // when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:92:04:00:40"
      }
    }
    server = {
      provider_settings = {
        mac = "aa:b2:92:04:00:41"
      }
      additional_repos = {
        pull_request_repo = var.PULL_REQUEST_REPO,
      }
      image = "sles15sp4o"
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
      server_mounted_mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
    }
    proxy = {
      provider_settings = {
        mac = "aa:b2:92:04:00:42"
      }
      additional_repos = {
        pull_request_repo = var.PULL_REQUEST_REPO,
      }
      image = "sles15sp4o"
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-minion = {
      image = "sles15sp4o"
      name = "min-suse"
      provider_settings = {
        mac = "aa:b2:92:04:00:44"
      }
      additional_repos = {
        tools_update_pr = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = "sles15sp4o"
      name = "minssh-suse"
      provider_settings = {
        mac = "aa:b2:92:04:00:45"
      }
      additional_repos = {
        tools_update_pr = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion", "iptables" ]
      install_salt_bundle = true
    }
    redhat-minion = {
      image = "rocky9o"
      name = "min-rhlike"
      provider_settings = {
        mac = "aa:b2:92:04:00:46"
        memory = 2048
        vcpu = 2
      }
      additional_repos = {
        client_repo = var.RHLIKE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
//    debian-minion = {
//      image = "ubuntu2204o"
//      name = "min-deblike"
//      provider_settings = {
//        mac = "aa:b2:92:04:00:47"
//      }
//      additional_repos = {
//        client_repo = var.DEBLIKE_CLIENT_REPO,
//      }
//      additional_packages = [ "venv-salt-minion" ]
//      install_salt_bundle = true
//    }
    build-host = {
      image = "sles15sp4o"
      name = "min-build"
      provider_settings = {
        mac = "aa:b2:92:04:00:49"
        memory = 2048
      }
      additional_repos = {
        tools_update_pr = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    pxeboot-minion = {
      image = "sles15sp4o"
      additional_repos = {
        tools_update_pr = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    kvm-host = {
      image = "sles15sp4o"
      name = "min-kvm"
      
      provider_settings = {
        mac = "aa:b2:92:04:00:4a"
      }
      additional_repos = {
        tools_update_pr = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion", "mkisofs" ]
      install_salt_bundle = true
    }
  }

  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br1"
    additional_network = "192.168.105.0/24"
  }
}


resource "null_resource" "add_test_information" {
  triggers = {
    always_run = "${timestamp()}"
  }
 provisioner "file" {
    source      = "../../susemanager-ci/terracumber_config/scripts/set_custom_header.sh"
    destination = "/tmp/set_custom_header.sh"
    connection {
      type     = "ssh"
      user     = "root"
      password = "linux"
      host     = "${module.cucumber_testsuite.configuration.server.hostname}"
    }
  }
}


output "configuration" {
  value = module.cucumber_testsuite.configuration
}
