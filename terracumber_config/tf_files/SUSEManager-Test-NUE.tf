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

  product_version = "head"
  
  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["centos7", "opensuse150", "sles15sp1", "sles15sp2", "ubuntu1804"]

  use_avahi    = false
  name_prefix  = "suma-test-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  portus_uri = "portus.mgr.suse.de:5000/cucutest"
  portus_username = "cucutest"
  portus_password = "cucusecret"

  server_http_proxy = "galaxy-proxy.mgr.suse.de:3128"

  host_settings = {
    ctl = {
      provider_settings = {
        mac    = "AA:B2:93:00:00:63"
      }
//      branch = "fix-login"
    }
    srv = {
      provider_settings = {
        mac = "AA:B2:93:00:00:60"
      }
//      additional_repos = {
//        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST/SLE_15_SP2/"
//        Server_repo = "http://dist.nue.suse.com/ibs/SUSE:/SLE-15-SP2:/GA:/TEST/images/repo/SLE-15-SP2-Module-Server-Applications-POOL-x86_64-Media1/"
//        Base_repo = "http://dist.nue.suse.com/ibs/SUSE:/SLE-15-SP2:/GA:/TEST/images/repo/SLE-15-SP2-Module-Basesystem-POOL-x86_64-Media1/"
//        Web_repo = "http://dist.nue.suse.com/ibs/SUSE:/SLE-15-SP2:/GA:/TEST/images/repo/SLE-15-SP2-Module-Web-Scripting-POOL-x86_64-Media1/"
//      }
    }
    pxy = {
      provider_settings = {
        mac = "AA:B2:93:00:00:86"
      }
    }
    cli-sles12sp4 = {
      image = "sles15sp1"
      name = "cli-sles15"
      provider_settings = {
        mac = "AA:B2:93:00:00:61"
      }
    }
    min-sles12sp4 = {
      image = "sles15sp1"
      name = "min-sles15"
      provider_settings = {
        mac = "AA:B2:93:00:00:62"
      }
    }
    min-build = {
      image = "sles15sp1"
      name = "min-build"
      provider_settings = {
        mac = "AA:B2:93:00:00:73"
      }
    }
    minssh-sles12sp4 = {
      image = "sles15sp1"
      name = "minssh-sles15"
      provider_settings = {
        mac = "AA:B2:93:00:00:64"
      }
    }
    min-centos7 = {
      provider_settings = {
        mac = "AA:B2:93:00:00:65"
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Still researching, but it will do it for now
        memory = 2048
        vcpu = 2
      }
    }
    min-ubuntu1804 = {
      provider_settings = {
        mac = "AA:B2:93:00:00:68"
      }
    }
    min-pxeboot = {
      present = true
      image = "sles15sp1"
    }
    min-kvm = {
      image = "sles15sp1"
      provider_settings = {
        mac = "AA:B2:93:00:00:69"
      }
    }
  }
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br0"
    additional_network = "192.168.140.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
