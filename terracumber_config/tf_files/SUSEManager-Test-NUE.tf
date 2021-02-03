// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Manager-Test/job/manager-TEST-cucumber"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = "string"
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = "string"
  default = "https://github.com/SUSE/spacewalk.git"
}

variable "CUCUMBER_BRANCH" {
  type = "string"
  default = "Manager-4.1-MU-4.1.5"
}

variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results TEST $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results TEST: Environment setup failed"
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
  uri = "qemu+tcp://cthulu.mgr.suse.de/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "4.1-released"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["centos7o", "opensuse152o", "sles15sp1o", "sles15sp2o", "ubuntu1804o"]

  use_avahi    = false
  name_prefix  = "suma-test-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry = "registry.mgr.suse.de"
  auth_registry = "portus.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  server_http_proxy = "galaxy-proxy.mgr.suse.de:3128"

  host_settings = {
    controller = {
      provider_settings = {
        mac    = "AA:B2:93:00:00:63"
      }
//      branch = "fix-login"
    }
    server = {
      provider_settings = {
        mac = "AA:B2:93:00:00:60"
      }
      additional_repos = {
        server_stack = "http://download.suse.de/ibs/SUSE:/Maintenance:/17859/SUSE_Updates_SLE-Module-SUSE-Manager-Server_4.1_x86_64/",
        salt15sp2_base = "http://download.suse.de/ibs/SUSE:/Maintenance:/17878/SUSE_Updates_SLE-Module-Basesystem_15-SP2_x86_64/",
        salt15sp2_python2_module = "http://download.suse.de/ibs/SUSE:/Maintenance:/17878/SUSE_Updates_SLE-Module-Python2_15-SP2_x86_64/",
        salt15sp2_server_apps_module = "http://download.suse.de/ibs/SUSE:/Maintenance:/17878/SUSE_Updates_SLE-Module-Server-Applications_15-SP2_x86_64/",
        Test_repo = "https://download.suse.de/ibs/home:/brejoc:/branches:/SUSE:/Maintenance:/17878/SUSE_SLE-15-SP2_Update/",
        sapformular = "http://download.suse.de/ibs/SUSE:/Maintenance:/17953/SUSE_Updates_SLE-Module-SUSE-Manager-Server_4.1_x86_64/",
        hwdata = "http://download.suse.de/ibs/SUSE:/Maintenance:/17927/SUSE_Updates_SLE-Module-SUSE-Manager-Server_4.1_x86_64/"
      }
    }
    proxy = {
      provider_settings = {
        mac = "AA:B2:93:00:00:86"
      }
      additional_repos = {
        proxy_stack = "http://download.suse.de/ibs/SUSE:/Maintenance:/17859/SUSE_Updates_SLE-Module-SUSE-Manager-Proxy_4.1_x86_64/",
        salt15sp2_base = "http://download.suse.de/ibs/SUSE:/Maintenance:/17878/SUSE_Updates_SLE-Module-Basesystem_15-SP2_x86_64/",
        salt15sp2_python2_module = "http://download.suse.de/ibs/SUSE:/Maintenance:/17878/SUSE_Updates_SLE-Module-Python2_15-SP2_x86_64/",
        salt15sp2_proxy_apps_module = "http://download.suse.de/ibs/SUSE:/Maintenance:/17878/SUSE_Updates_SLE-Module-Proxy-Applications_15-SP2_x86_64/",
        Test_repo = "https://download.suse.de/ibs/home:/brejoc:/branches:/SUSE:/Maintenance:/17878/SUSE_SLE-15-SP2_Update/"
      }
    }
    suse-client = {
      image = "sles15sp1o"
      name = "cli-sles15"
      provider_settings = {
        mac = "AA:B2:93:00:00:61"
      }
      additional_repos = {
        Test_repo = "https://download.suse.de/ibs/home:/brejoc:/branches:/SUSE:/Maintenance:/17876/SUSE_SLE-15-SP1_Update/"
      }
    }
    suse-minion = {
      image = "sles15sp1o"
      name = "min-sles15"
      provider_settings = {
        mac = "AA:B2:93:00:00:62"
      }
      additional_repos = {
        Test_repo = "https://download.suse.de/ibs/home:/brejoc:/branches:/SUSE:/Maintenance:/17876/SUSE_SLE-15-SP1_Update/"
      }
    }
  }
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br0"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
