// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-tests-hub-NUE"
}

variable "CUCUMBER_COMMAND" {
  type = "string"
  default = "export PRODUCT='Uyuni' && run-testsuite #TODO run only sanity, core and hub tests, including reporting"
}

variable "CUCUMBER_GITREPO" {
  type = "string"
  default = "https://github.com/uyuni-project/uyuni.git"
}

variable "CUCUMBER_BRANCH" {
  type = "string"
  default = "master"
}

variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results Uyuni Tests Hub $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results Uyuni Tests Hub: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = "string"
  default = "galaxy-ci@suse.de"
}

variable "MAIL_TO" {
  type = "string"
  default = "galaxy-ci@suse.de"
}

// sumaform specific variables
variable "SCC_USER" {
  type = "string"
}

variable "SCC_PASSWORD" {
  type = "string"
}

variable "GIT_USER" {
  type = "string"
  default = null // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type = "string"
  default = null // Not needed for master, as it is public
}

provider "libvirt" {
  uri = "qemu+tcp://salzbreze.mgr.suse.de/system"
}


module "base" {
  source = "./modules/base"
  images = ["centos7o", "sles15sp4o", "ubuntu2004o"]
  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
}

module "hub-server" {
  source = "./modules/server"
  image = "sles15sp4o"
  base_configuration = module.base.configuration
  product_version = "head"
  name = "uyuni-tests-hub-server"
  use_os_released_updates = false
  additional_repos = {
    Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Orion/SLE_15_SP4/"
  }
}

module "server-2" {
  source = "./modules/server"
  image = "sles15sp4o"
  base_configuration = module.base.configuration
  name = "uyuni-tests-hub-slave-2"
  product_version = "head"
  use_os_released_updates = false
  register_to_server = module.hub-server.configuration.hostname
  auto_accept = false
  additional_repos = {
    Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Orion/SLE_15_SP4/"
  }
}

module "server-3" {
  source = "./modules/server"
  image = "sles15sp4o"
  base_configuration = module.base.configuration
  name = "uyuni-tests-hub-slave-3"
  product_version = "head"
  use_os_released_updates = false
  register_to_server = module.hub-server.configuration.hostname
  auto_accept = false
  additional_repos = {
    Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Orion/SLE_15_SP4/"
  }
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

  images = ["centos7o", "sles15sp4o", "ubuntu2004o"]

  use_avahi    = false
  name_prefix  = "uyuni-tests-hub-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry = "registry.mgr.suse.de"
  auth_registry = "portus.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"

  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  server_http_proxy = "galaxy-proxy.mgr.suse.de:3128"

  host_settings = {
    server = {
      name = "slave-1"
      image = "sles15sp4o"
      additional_repos = {
          Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Orion/SLE_15_SP4/"
      }
      use_os_released_updates = false
      register_to_server = module.hub-server.configuration.hostname
      auto_accept = true
    }
    suse-minion = {
      image = "sles15s4o"
      name = "min-sles15"
    }
    suse-sshminion = {
      image = "sles15sp4o"
      name = "minssh-sles15"
    }
    redhat-minion = {
      provider_settings = {
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Still researching, but it will do it for now
        memory = 2048
        vcpu = 2
      }
    }
    debian-minion = {
      name = "min-ubuntu2004"
      image = "ubuntu2004o"
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
