// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-master-qe-build-validation"
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
  default = "Results Uyuni Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Uyuni Build Validation: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = string
  default = "galaxy-noise@suse.de"
}

variable "MAIL_TO" {
  type = string
  default = "galaxy-noise@suse.de"
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
  uri = "qemu+tcp://suma-06.mgr.suse.de/system"
}

//provider "libvirt" {
//  alias = "overdrive3"
//  uri = "qemu+tcp://overdrive3.mgr.suse.de/system"
//}

module "base_core" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.suse.de"
  images      = [ "sles12sp4o", "sles12sp5o", "sles15sp1o", "sles15sp2o", "sles15sp3o", "sles15sp4o", "sles15sp5o", "slemicro51-ign", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "almalinux9o", "centos7o", "oraclelinux9o", "rocky8o", "rocky9o", "ubuntu2004o", "ubuntu2204o", "debian10o", "debian11o", "opensuse154o" ]

  mirror = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br0"
    additional_network = "192.168.100.0/24"
  }
}

// WORKAROUND: overdrive3 has been disconnected by mistake
//module "base_arm" {
//  providers = {
//    libvirt = libvirt.overdrive3
//  }
//
//  source = "./modules/base"
//
//  cc_username = var.SCC_USER
//  cc_password = var.SCC_PASSWORD
//  name_prefix = "uyuni-bv-master-"
//  use_avahi   = false
//  domain      = "mgr.suse.de"
//  images      = [ "opensuse154armo", "opensuse155armo" ]
//
//  mirror = "minima-mirror-ci-bv.mgr.suse.de"
//  use_mirror_images = true
//
//  testsuite = true
//
//  provider_settings = {
//    pool        = "ssd"
//    bridge      = "br1"
//  }
//}

module "server" {
  source             = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "srv"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a1"
    memory             = 40960
    vcpu               = 10
    data_pool          = "ssd"
  }

  server_mounted_mirror = "minima-mirror-ci-bv.mgr.suse.de"
  repository_disk_size = 2048

  java_debugging                 = false
  auto_accept                    = false
  monitored                      = true
  disable_firewall               = false
  allow_postgres_connections     = false
  skip_changelog_import          = false
  create_first_user              = false
  mgr_sync_autologin             = false
  create_sample_channel          = false
  create_sample_activation_key   = false
  create_sample_bootstrap_script = false
  publish_private_ssl_key        = false
  use_os_released_updates        = true
  disable_download_tokens        = false
  disable_auto_bootstrap         = true
  ssh_key_path                   = "./salt/controller/id_rsa.pub"
  from_email                     = "root@suse.de"
  accept_all_ssl_protocols       = true

  //server_additional_repos

}

module "proxy" {
  source             = "./modules/proxy"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "pxy"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a2"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-srv.mgr.suse.de"
    username = "admin"
    password = "admin"
  }
  auto_register             = false
  auto_connect_to_master    = false
  download_private_ssl_key  = false
  install_proxy_pattern     = false
  auto_configure            = false
  generate_bootstrap_script = false
  publish_private_ssl_key   = false
  use_os_released_updates   = true
  ssh_key_path              = "./salt/controller/id_rsa.pub"
}

// No traditional clients in Uyuni

module "sles12sp4-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b0"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp5-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b1"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp1-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b3"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp2-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b4"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp3-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b5"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b6"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp5-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b2"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "alma9-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-alma9"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c2"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "centos7-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b7"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "oracle9-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c3"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky8-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-rocky8"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b8"

    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky9-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-rocky9"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c1"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2004-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:ba"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu2204-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:bb"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

// Debian 9 is not supported by 4.3

module "debian10-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-debian10"
  image              = "debian10o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:bd"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian11-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-debian11"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:be"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

// WORKAROUND: overdrive3 has been disconnected by mistake
//module "opensuse154arm-minion" {
//  providers = {
//    libvirt = libvirt.overdrive3
//  }
//  source             = "./modules/minion"
//  base_configuration = module.base_arm.configuration
//  product_version    = "uyuni-master"
//  name               = "min-opensuse154arm"
//  image              = "opensuse154armo"
//  provider_settings = {
//    mac                = "aa:b2:93:02:01:bf"
//    memory             = 2048
//    vcpu               = 2
//    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
//  }
//  server_configuration = {
//    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
//  }
//  auto_connect_to_master  = false
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//}

// WORKAROUND: overdrive3 has been disconnected by mistake
//module "opensuse155arm-minion" {
//  providers = {
//    libvirt = libvirt.overdrive3
//  }
//  source             = "./modules/minion"
//  base_configuration = module.base_arm.configuration
//  product_version    = "uyuni-master"
//  name               = "min-opensuse155arm"
//  image              = "opensuse155armo"
//  provider_settings = {
//    mac                = "aa:b2:93:02:01:c0"
//    memory             = 2048
//    vcpu               = 2
//    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
//  }
//  server_configuration = {
//    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
//  }
//  auto_connect_to_master  = false
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//}

module "slemicro51-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-slemicro51"
  image              = "slemicro51-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c6"
    memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro52-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-slemicro52"
  image              = "slemicro52-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c7"
    memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro53-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-slemicro53"
  image              = "slemicro53-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c8"
    memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro54-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "min-slemicro54"
  image              = "slemicro54-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c9"
    memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp4-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d0"
    memory             = 4096
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]
}

module "sles12sp5-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d1"
    memory             = 4096
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]
}

module "sles15sp1-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d3"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

}

module "sles15sp2-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d4"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp3-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d5"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d6"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp5-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d2"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "alma9-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-alma9"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:e2"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "centos7-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d7"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "oracle9-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:e3"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky8-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-rocky8"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d8"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky9-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-rocky9"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:e1"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2004-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:da"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu2204-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:db"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

// Debian 9 is not supported by 4.3

module "debian10-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-debian10"
  image              = "debian10o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:dd"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian11-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-debian11"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:de"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

// WORKAROUND: overdrive3 has been disconnected by mistake
//module "opensuse154arm-sshminion" {
//  providers = {
//    libvirt = libvirt.overdrive3
//  }
//  source             = "./modules/sshminion"
//  base_configuration = module.base_arm.configuration
//  product_version    = "uyuni-master"
//  name               = "minssh-opensuse154arm"
//  image              = "opensuse154armo"
//  provider_settings = {
//    mac                = "aa:b2:93:02:01:df"
//    memory             = 2048
//    vcpu               = 2
//    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
//  }
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//}

// WORKAROUND: overdrive3 has been disconnected by mistake
//module "opensuse155arm-sshminion" {
//  providers = {
//    libvirt = libvirt.overdrive3
//  }
//  source             = "./modules/sshminion"
//  base_configuration = module.base_arm.configuration
//  product_version    = "uyuni-master"
//  name               = "minssh-opensuse155arm"
//  image              = "opensuse155armo"
//  provider_settings = {
//    mac                = "aa:b2:93:02:01:e0"
//    memory             = 2048
//    vcpu               = 2
//    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
//  }
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//}

module "slemicro51-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-slemicro51"
  image              = "slemicro51-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:e6"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro52-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-slemicro52"
  image              = "slemicro52-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:e7"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro53-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-slemicro53"
  image              = "slemicro53-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:e8"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro54-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "minssh-slemicro54"
  image              = "slemicro54-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:e9"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp5-buildhost" {
  source             = "./modules/build_host"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "build-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a4"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp5-terminal" {
  source             = "./modules/pxe_boot"
  base_configuration = module.base_core.configuration
  name               = "terminal-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    memory             = 2048
    vcpu               = 1
    manufacturer       = "Supermicro"
    product            = "X9DR3-F"
  }
}

module "sles15sp4-buildhost" {
  source             = "./modules/build_host"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "build-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a5"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4-terminal" {
  source             = "./modules/pxe_boot"
  base_configuration = module.base_core.configuration
  name               = "terminal-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    memory             = 2048
    vcpu               = 2
    manufacturer       = "HP"
    product            = "ProLiant DL360 Gen9"
  }
}

module "monitoring-server" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "monitoring"
  image              = "opensuse154o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a3"
    memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base_core.configuration
  name               = "ctl"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a0"
    memory             = 16384
    vcpu               = 8
  }
  swap_file_size = null

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration = module.server.configuration
  proxy_configuration  = module.proxy.configuration

  sle12sp4_minion_configuration    = module.sles12sp4-minion.configuration
  sle12sp4_sshminion_configuration = module.sles12sp4-sshminion.configuration

  sle12sp5_minion_configuration    = module.sles12sp5-minion.configuration
  sle12sp5_sshminion_configuration = module.sles12sp5-sshminion.configuration

  sle15sp1_minion_configuration    = module.sles15sp1-minion.configuration
  sle15sp1_sshminion_configuration = module.sles15sp1-sshminion.configuration

  sle15sp2_minion_configuration    = module.sles15sp2-minion.configuration
  sle15sp2_sshminion_configuration = module.sles15sp2-sshminion.configuration

  sle15sp3_minion_configuration    = module.sles15sp3-minion.configuration
  sle15sp3_sshminion_configuration = module.sles15sp3-sshminion.configuration

  sle15sp4_minion_configuration    = module.sles15sp4-minion.configuration
  sle15sp4_sshminion_configuration = module.sles15sp4-sshminion.configuration

  sle15sp5_minion_configuration    = module.sles15sp5-minion.configuration
  sle15sp5_sshminion_configuration = module.sles15sp5-sshminion.configuration

  alma9_minion_configuration    = module.alma9-minion.configuration
  alma9_sshminion_configuration = module.alma9-sshminion.configuration

  centos7_minion_configuration    = module.centos7-minion.configuration
  centos7_sshminion_configuration = module.centos7-sshminion.configuration

  oracle9_minion_configuration    = module.oracle9-minion.configuration
  oracle9_sshminion_configuration = module.oracle9-sshminion.configuration

  rocky8_minion_configuration    = module.rocky8-minion.configuration
  rocky8_sshminion_configuration = module.rocky8-sshminion.configuration

  rocky9_minion_configuration    = module.rocky9-minion.configuration
  rocky9_sshminion_configuration = module.rocky9-sshminion.configuration

  ubuntu2004_minion_configuration    = module.ubuntu2004-minion.configuration
  ubuntu2004_sshminion_configuration = module.ubuntu2004-sshminion.configuration

  ubuntu2204_minion_configuration    = module.ubuntu2204-minion.configuration
  ubuntu2204_sshminion_configuration = module.ubuntu2204-sshminion.configuration

  debian10_minion_configuration    = module.debian10-minion.configuration
  debian10_sshminion_configuration = module.debian10-sshminion.configuration

  debian11_minion_configuration    = module.debian11-minion.configuration
  debian11_sshminion_configuration = module.debian11-sshminion.configuration

// WORKAROUND: overdrive3 has been disconnected by mistake
//  opensuse154arm_minion_configuration    = module.opensuse154arm-minion.configuration
//  opensuse154arm_sshminion_configuration = module.opensuse154arm-sshminion.configuration
//
//  opensuse155arm_minion_configuration    = module.opensuse155arm-minion.configuration
//  opensuse155arm_sshminion_configuration = module.opensuse155arm-sshminion.configuration

  slemicro51_minion_configuration    = module.slemicro51-minion.configuration
  slemicro51_sshminion_configuration = module.slemicro51-sshminion.configuration

  slemicro52_minion_configuration    = module.slemicro52-minion.configuration
  slemicro52_sshminion_configuration = module.slemicro52-sshminion.configuration

  slemicro53_minion_configuration    = module.slemicro53-minion.configuration
  slemicro53_sshminion_configuration = module.slemicro53-sshminion.configuration

  slemicro54_minion_configuration    = module.slemicro54-minion.configuration
  slemicro54_sshminion_configuration = module.slemicro54-sshminion.configuration

  sle12sp5_buildhost_configuration = module.sles12sp5-buildhost.configuration
  sle15sp4_buildhost_configuration = module.sles15sp4-buildhost.configuration

  sle12sp5_terminal_configuration = module.sles12sp5-terminal.configuration
  sle15sp4_terminal_configuration = module.sles15sp4-terminal.configuration

  monitoringserver_configuration = module.monitoring-server.configuration
}

output "configuration" {
  value = {
    controller = module.controller.configuration
  }
}
