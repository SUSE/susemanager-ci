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
  default = "Results Uyuni-Master NUE $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Uyuni-Master NUE: Environment setup failed"
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
  uri = "qemu+tcp://suma-01.mgr.suse.de/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite_temporary"

  product_version = "uyuni-master"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["rocky8o", "opensuse155o", "ubuntu2204o", "sles15sp4o"]

  use_avahi     = false
  name_prefix   = "uyuni-ci-master-"
  domain        = "mgr.suse.de"
  from_email    = "root@suse.de"

  no_auth_registry          = "registry.mgr.suse.de"
  auth_registry             = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username    = "cucutest"
  auth_registry_password    = "cucusecret"
  git_profiles_repo         = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  mirror                    = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images         = true
  server_http_proxy         = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint  = "ftp://minima-mirror-ci-bv.mgr.suse.de:445"

  # when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      name              = "controller"
      provider_settings = {
        mac     = "aa:b2:93:01:00:d0"
        vcpu    = 2
        memory  = 2048
      }
    }
    server = {
      name                  = "server"
      provider_settings     = {
        mac     = "aa:b2:93:01:00:d1"
        vcpu    = 4
        memory  = 16384
      }
      main_disk_size        = 20
      repository_disk_size  = 300
      database_disk_size    = 50
      login_timeout         = 28800
    }
    proxy = {
      name              = "proxy"
      provider_settings = {
        mac     = "aa:b2:93:01:00:d2"
        vcpu    = 2
        memory  = 2048
      }
    }
    suse_minion = {
      name              = "suse-minion"
      image             = "opensuse155o"
      provider_settings = {
        mac     = "aa:b2:93:01:00:d6"
        vcpu    = 2
        memory  = 2048
      }
    }
    suse_sshminion = {
      name              = "suse-sshminion"
      image             = "opensuse155o"
      provider_settings = {
        mac     = "aa:b2:93:01:00:d8"
        vcpu    = 2
        memory  = 2048
      }
    }
    rhlike_minion = {
      name              = "rhlike-minion"
      image             = "rocky8o"
      provider_settings = {
        mac     = "aa:b2:93:01:00:d9"
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Also, openscap cannot run with less than 1.25 GB of RAM
        vcpu    = 2
        memory  = 2048
      }
    }
    deblike_minion = {
      name              = "deblike-minion"
      image             = "ubuntu2204o"
      provider_settings = {
        mac     = "aa:b2:93:01:00:db"
        vcpu    = 2
        memory  = 2048
      }
    }
    build_host = {
      name              = "build-host"
      image             = "sles15sp4o"
      provider_settings = {
        mac     = "aa:b2:93:01:00:dd"
        vcpu    = 2
        memory  = 2048
      }
    }
    pxeboot_minion = {
      name                  = "pxeboot-minion"
      image                 = "sles15sp4o"
      additional_packages   = [ "venv-salt-minion" ]
      install_salt_bundle   = true
    }
    kvm-host = {
      name  = "kvm-minion"
      image = "opensuse155o"
      
      provider_settings = {
        mac     = "aa:b2:93:01:00:de"
        vcpu    = 4
        memory  = 4096
      }
      additional_packages = [ "mkisofs" ]
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
