// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-Test/job/manager-TEST-acceptance-tests"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
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
  default = "Results TEST $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results TEST: Environment setup failed"
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

  product_version = "head"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["centos7o", "opensuse152o", "sles15sp4o", "ubuntu2204o"]

  use_avahi    = false
  name_prefix  = "suma-test-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry = "registry.mgr.suse.de"
  auth_registry = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  server_http_proxy = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint = "ftp://minima-mirror.mgr.suse.de:445"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:93:01:00:40"
      }
    }
    server = {
      provider_settings = {
        mac = "aa:b2:93:01:00:41"
        memory = 10240
      }
//    additional_repos = {
//      server_stack = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST/images/repo/SLE-Module-SUSE-Manager-Server-4.3-POOL-x86_64-Media1/"
//        salt15sp2_base = "http://download.suse.de/ibs/SUSE:/Maintenance:/17878/SUSE_Updates_SLE-Module-Basesystem_15-SP2_x86_64/",
//        salt15sp2_python2_module = "http://download.suse.de/ibs/SUSE:/Maintenance:/17878/SUSE_Updates_SLE-Module-Python2_15-SP2_x86_64/",
//        salt15sp2_server_apps_module = "http://download.suse.de/ibs/SUSE:/Maintenance:/17878/SUSE_Updates_SLE-Module-Server-Applications_15-SP2_x86_64/",
//        sapformular = "http://download.suse.de/ibs/SUSE:/Maintenance:/17953/SUSE_Updates_SLE-Module-SUSE-Manager-Server_4.1_x86_64/",
//        hwdata = "http://download.suse.de/ibs/SUSE:/Maintenance:/17927/SUSE_Updates_SLE-Module-SUSE-Manager-Server_4.1_x86_64/",
//        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/salt-testing/SLE_15_SP4/"
//        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/salt-testing:/sle15sp4/standard/"
//        Test_repo_2 = "http://download.suse.de/ibs/home:/PSuarezHernandez:/branches:/openSUSE.org:/systemsmanagement/SLE_15_SP4/"
//    }
//    additional_packages = [ "cobbler" ]
    }
    proxy = {
      provider_settings = {
        mac = "aa:b2:93:01:00:42"
      }
//    additional_repos = {
//        proxy_stack = "http://download.suse.de/ibs/SUSE:/Maintenance:/17859/SUSE_Updates_SLE-Module-SUSE-Manager-Proxy_4.1_x86_64/",
//        salt15sp2_base = "http://download.suse.de/ibs/SUSE:/Maintenance:/17878/SUSE_Updates_SLE-Module-Basesystem_15-SP2_x86_64/",
//        salt15sp2_python2_module = "http://download.suse.de/ibs/SUSE:/Maintenance:/17878/SUSE_Updates_SLE-Module-Python2_15-SP2_x86_64/",
//        salt15sp2_server_apps_module = "http://download.suse.de/ibs/SUSE:/Maintenance:/17878/SUSE_Updates_SLE-Module-Server-Applications_15-SP2_x86_64/",
//        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/salt-testing:/sle15sp4/standard/"
//    }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-client = {
      image = "sles15sp4o"
      name = "cli-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:44"
      }
//    additional_repos = {
//        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/salt-testing:/sle15sp2/standard/"
//    }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-minion = {
      image = "sles15sp4o"
      name = "min-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:46"
      }
//    additional_repos = {
//        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/salt-testing:/sle15sp2/standard/"
//    }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = "sles15sp4o"
      name = "minssh-sles15"
      provider_settings = {
        mac = "aa:b2:93:01:00:48"
      }
//    additional_repos = {
//        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/salt-testing:/sle15sp2/standard/"
//    }
      additional_packages = [ "venv-salt-minion", "iptables" ]
      install_salt_bundle = true
    }
    redhat-minion = {
      image = "centos7o"
      provider_settings = {
        mac = "aa:b2:93:01:00:49"
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Also, openscap cannot run with less than 1.25 GB of RAM
        memory = 2048
        vcpu = 2
      }
//    additional_repos = {
//        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/Head:/RES7-SUSE-Manager-Tools:/SaltBundle/SUSE_RES-7_Update_standard/"
//    }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    debian-minion = {
      name = "min-ubuntu2204"
      image = "ubuntu2204o"
      provider_settings = {
        mac = "aa:b2:93:01:00:4b"
      }
//    additional_repos = {
//        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/salt-testing:/ubuntu22.04/standard/"
//    }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    build-host = {
      image = "sles15sp4o"
      name = "min-build"
      provider_settings = {
        mac = "aa:b2:93:01:00:4d"
        memory = 2048
        vcpu = 2
      }
//    additional_repos = {
//        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/salt-testing:/sle15sp2/standard/"
//        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/salt-testing/SLE_15_SP2/"
//    }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    pxeboot-minion = {
      image = "sles15sp4o"
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    kvm-host = {
      image = "sles15sp4o"
      provider_settings = {
        mac = "aa:b2:93:01:00:4e"
      }
//    additional_repos = {
//      Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/salt-testing:/sle15sp3/standard/"
//      Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/salt-testing/SLE_15_SP3/"
//    }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
//    xen-host = {
//      image = "sles15sp4o"
//      name = "min-xen"
//      provider_settings = {
//        mac = "aa:b2:93:01:00:4f"
//      }
//      additional_repos = {
//        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/salt-testing:/sle15sp2/standard/"
//      }
//      additional_packages = [ "venv-salt-minion" ]
//      install_salt_bundle = true
//    }
  }
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br0"
    additional_network = "192.168.41.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
