// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-Test/job/manager-TEST-Orion-acceptance-tests"
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
  uri = "qemu+tcp://cthulhu.mgr.suse.de/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  //product_version = "uyuni-master"
  product_version = "head"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  //images = ["opensuse152o", "sles15sp2o", "sles15sp3o", "sles15sp4o", "ubuntu2004o"]
  images = ["centos7o", "opensuse152o", "sles15sp2o", "sles15sp3o", "sles15sp4o", "ubuntu2004o"]

  use_avahi    = false
  name_prefix  = "suma-testorion-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry = "registry.mgr.suse.de"
  auth_registry = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  server_http_proxy = "http-proxy.mgr.suse.de:3128"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:93:01:00:70"
      }
    }
    server = {
      provider_settings = {
        mac = "aa:b2:93:01:00:71"
        memory = 10240
      }
      additional_repos = {
        //Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Orion/openSUSE_Leap_15.3/"
        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Orion/SLE_15_SP4/"
      }
    }
    proxy = {
      provider_settings = {
        mac = "aa:b2:93:01:00:72"
      }
      additional_repos = {
        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Orion/SLE_15_SP4/"
        Salt_repo = "https://download.opensuse.org/repositories/systemsmanagement:/saltstack:/bundle:/testing:/SLE15/SLE_15/"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-client = {
      image = "sles15sp2o"
      name = "cli-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:74"
      }
      additional_repos = {
        Salt_repo = "https://download.opensuse.org/repositories/systemsmanagement:/saltstack:/bundle:/testing:/SLE15/SLE_15/"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-minion = {
      image = "sles15sp2o"
      name = "min-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:76"
      }
      additional_repos = {
        Salt_repo = "https://download.opensuse.org/repositories/systemsmanagement:/saltstack:/bundle:/testing:/SLE15/SLE_15/"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = "sles15sp2o"
      name = "minssh-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:78"
      }
      additional_repos = {
        Salt_repo = "https://download.opensuse.org/repositories/systemsmanagement:/saltstack:/bundle:/testing:/SLE15/SLE_15/"
      }
      additional_packages = [ "venv-salt-minion", "iptables" ]
      install_salt_bundle = true
    }
    redhat-minion = {
      provider_settings = {
        mac = "aa:b2:93:01:00:79"
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Still researching, but it will do it for now
        memory = 2048
        vcpu = 2
      }
      additional_repos = {
        Salt_repo = "https://download.opensuse.org/repositories/systemsmanagement:/saltstack:/bundle:/testing:/CentOS7/CentOS_7/"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    pxeboot-minion = {
      image = "sles15sp3o"
    }
    debian-minion = {
      name = "min-ubuntu2004"
      image = "ubuntu2004o"
      provider_settings = {
        mac = "aa:b2:93:01:00:7b"
      }
      additional_repos = {
        Salt_repo = "https://download.opensuse.org/repositories/systemsmanagement:/saltstack:/bundle:/testing:/Ubuntu2004/Ubuntu_20.04/"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    build-host = {
      image = "sles15sp2o"
      provider_settings = {
        mac = "aa:b2:93:01:00:7d"
        memory = 2048
      }
      additional_repos = {
        Salt_repo = "https://download.opensuse.org/repositories/systemsmanagement:/saltstack:/bundle:/testing:/SLE15/SLE_15/"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
  }
  provider_settings = {
    pool         = "ssd"
    network_name = null
    bridge       = "br0"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
