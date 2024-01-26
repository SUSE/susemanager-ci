// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-qe/job/manager-5.0-qe-build-validation-PRV"
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
  default = "Results 5.0 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results HEAD Build Validation: Environment setup failed"
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

variable "ZVM_ADMIN_TOKEN" {
  type = string
}

terraform {
  required_version = "1.0.10"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.3"
    }
    feilong = {
      source = "bischoff/feilong"
      version = "0.0.4"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://caipirinha.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "cosmopolitan"
  uri = "qemu+tcp://cosmopolitan.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "ginfizz"
  uri = "qemu+tcp://ginfizz.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "hugo"
  uri = "qemu+tcp://hugo.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "irishcoffee"
  uri = "qemu+tcp://irishcoffee.mgr.prv.suse.net/system"
}

// WORKAROUND: overdrive4 will be replaced with a new ARM server
//provider "libvirt" {
//  alias = "overdrive4"
//  uri = "qemu+tcp://overdrive4.mgr.suse.de/system"
//}

provider "feilong" {
  connector   = "https://10.144.68.9"
  admin_token = var.ZVM_ADMIN_TOKEN
  local_user  = "jenkins@jenkins-worker.mgr.prv.suse.net"
}

module "base_core" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles15sp4o", "opensuse155o" ]

  mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
    additional_network = "192.168.50.0/24"
  }
}

module "base_old_sle" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles12sp5o" ]

  mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

module "base_res" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "almalinux9o", "centos7o", "oraclelinux9o", "rocky8o", "rocky9o" ]

  mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

module "base_new_sle" {
  providers = {
    libvirt = libvirt.ginfizz
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles15sp1o", "sles15sp2o", "sles15sp3o", "sles15sp4o", "sles15sp5o", "slemicro51-ign", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "slemicro55-ign" ]

  mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

module "base_retail" {
  providers = {
    libvirt = libvirt.hugo
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles12sp5o", "sles15sp3o", "sles15sp4o", "opensuse155o" ]

  mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
    additional_network = "192.168.50.0/24"
  }
}

module "base_debian" {
  providers = {
    libvirt = libvirt.irishcoffee
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "ubuntu2204o", "debian10o", "debian11o", "debian12o" ]

  mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

// WORKAROUND: overdrive4 will be replaced with a new ARM server
//module "base_arm" {
//  providers = {
//    libvirt = libvirt.overdrive4
//  }
//
//  source = "./modules/base"
//
//  cc_username = var.SCC_USER
//  cc_password = var.SCC_PASSWORD
//  name_prefix = "suma-bv-50"
//  use_avahi   = false
//  domain      = "mgr.prv.suse.net"
//  images      = [ "opensuse154armo", "opensuse155armo" ]
//
//  mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
//  use_mirror_images = true
//
//  testsuite = true
//
//  provider_settings = {
//    pool        = "ssd"
//    bridge      = "br1"
//  }
//}

module "base_s390" {
  source = "./backend_modules/feilong/base"

  name_prefix = "suma-bv-50-"
  domain      = "mgr.prv.suse.net"

  testsuite   = true
}

module "server_containerized" {
  source             = "./modules/server_containerized"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "srv"
  image              = "slemicro55-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:01"
    memory             = 40960
    vcpu               = 10
    data_pool          = "ssd"
  }
  runtime = "podman"
  container_repository = "registry.suse.de/devel/galaxy/manager/head/containers/suse/manager/5.0"

  server_mounted_mirror          = "minima-mirror-ci-bv.mgr.prv.suse.net"
  java_debugging                 = false
  auto_accept                    = false
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
  large_deployment               = true
  ssh_key_path                   = "./salt/controller/id_rsa.pub"
  from_email                     = "root@suse.de"

  //server_additional_repos

}

// WORKAROUND: We do the initial testing without a proxy and add it later
// This will also use a new upcoming proxy_containerized module
// See https://github.com/SUSE/spacewalk/issues/19280
// module "proxy" {
//  providers = {
//    libvirt = libvirt.hugo
//  }
//   source             = "./modules/proxy"
//   base_configuration = module.base_core.configuration
//   product_version    = "head"
//   name               = "pxy"
//   provider_settings = {
//     mac                = "aa:b2:92:42:00:02"
//     memory             = 4096
//   }
//   auto_register             = false
//   auto_connect_to_master    = false
//   download_private_ssl_key  = false
//   install_proxy_pattern     = false
//   auto_configure            = false
//   generate_bootstrap_script = false
//   publish_private_ssl_key   = false
//   use_os_released_updates   = true
//   ssh_key_path              = "./salt/controller/id_rsa.pub"
// }

module "sles12sp5-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "head"
  name               = "min-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:11"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp1-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "min-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:13"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp2-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "min-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:14"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp3-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "min-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:15"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "min-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:16"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp5-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "min-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:12"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "alma9-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "head"
  name               = "min-alma9"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:22"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "centos7-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "head"
  name               = "min-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:17"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "liberty9-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "head"
  name               = "min-liberty9"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:25"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "oracle9-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "head"
  name               = "min-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:23"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky8-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "head"
  name               = "min-rocky8"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:18"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky9-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "head"
  name               = "min-rocky9"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:21"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2004-minion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "head"
  name               = "min-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:1a"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  # WORKAROUND https://github.com/uyuni-project/uyuni/issues/7637
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2204-minion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "head"
  name               = "min-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:1b"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian11-minion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "head"
  name               = "min-debian11"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:1e"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian12-minion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "head"
  name               = "min-debian12"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:1c"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

// WORKAROUND: overdrive3 will be replaced with a new ARM server
// TODO: Please adjust the values below!
//module "opensuse154arm-minion" {
//  providers = {
//    libvirt = libvirt.overdrive3
//  }
//  source             = "./modules/minion"
//  base_configuration = module.base_arm.configuration
//  product_version    = "head"
//  name               = "min-o154arm-n"
//  image              = "opensuse154armo"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:6f"
//    memory             = 2048
//    vcpu               = 2
//    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
//  }
//  server_configuration = {
//    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
//  }
//  auto_connect_to_master  = false
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//}

// WORKAROUND: overdrive3 will be replaced with a new ARM server
// TODO: Please adjust the values below!
//module "opensuse155arm-minion" {
//  providers = {
//    libvirt = libvirt.overdrive3
//  }
//  source             = "./modules/minion"
//  base_configuration = module.base_arm.configuration
//  product_version    = "head"
//  name               = "min-o155arm-n"
//  image              = "opensuse155armo"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:70"
//    memory             = 2048
//    vcpu               = 2
//    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
//  }
//  server_configuration = {
//    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
//  }
//  auto_connect_to_master  = false
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//}

module "sles15sp5s390-minion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration

  name               = "min-sles15sp5s390"
  image              = "s15s5-minimal-2part-xfs"

  provider_settings = {
    userid             = "S50MIPRV"
    mac                = "02:3a:fc:02:01:32"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro51-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "min-slemicro51"
  image              = "slemicro51-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:26"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro52-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "min-slemicro52"
  image              = "slemicro52-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:27"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro53-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "min-slemicro53"
  image              = "slemicro53-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:28"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro54-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "min-slemicro54"
  image              = "slemicro54-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:29"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro55-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "min-slemicro55"
  image              = "slemicro55-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:2a"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp5-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "head"
  name               = "minssh-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:31"
    memory             = 4096
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]
}

module "sles15sp1-sshminion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "minssh-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:33"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

}

module "sles15sp2-sshminion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "minssh-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:34"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp3-sshminion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "minssh-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:35"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4-sshminion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "minssh-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:36"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp5-sshminion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "minssh-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:32"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "alma9-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "head"
  name               = "minssh-alma9"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:42"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "centos7-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "head"
  name               = "minssh-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:37"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "liberty9-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "head"
  name               = "minssh-liberty9"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:45"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "oracle9-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "head"
  name               = "minssh-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:43"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky8-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "head"
  name               = "minssh-rocky8"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:38"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky9-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "head"
  name               = "minssh-rocky9"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:41"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2004-sshminion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "head"
  name               = "minssh-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:3a"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  # WORKAROUND https://github.com/uyuni-project/uyuni/issues/7637
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2204-sshminion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "head"
  name               = "minssh-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:3b"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian11-sshminion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "head"
  name               = "minssh-debian11"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:3e"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian12-sshminion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "head"
  name               = "minssh-debian12"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:3c"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

// WORKAROUND: overdrive3 will be replaced with a new ARM server
// TODO: Please adjust the values below!
//module "opensuse154arm-sshminion" {
//  providers = {
//    libvirt = libvirt.overdrive3
//  }
//  source             = "./modules/sshminion"
//  base_configuration = module.base_arm.configuration
//  product_version    = "head"
//  name               = "minssh-o154arm-n"
//  image              = "opensuse154armo"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:8f"
//    memory             = 2048
//    vcpu               = 2
//    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
//  }
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//}

// WORKAROUND: overdrive3 will be replaced with a new ARM server
// TODO: Please adjust the values below!
//module "opensuse155arm-sshminion" {
//  providers = {
//    libvirt = libvirt.overdrive3
//  }
//  source             = "./modules/sshminion"
//  base_configuration = module.base_arm.configuration
//  product_version    = "head"
//  name               = "minssh-o155arm-n"
//  image              = "opensuse155armo"
//  provider_settings = {
//    mac                = "aa:b2:92:42:00:90"
//    memory             = 2048
//    vcpu               = 2
//    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
//  }
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//}

module "sles15sp5s390-sshminion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration

  name               = "minssh-sles15sp5s390"
  image              = "s15s3-jeos-1part-ext4"

  provider_settings = {
    userid             = "S50SSPRV"
    mac                = "02:3a:fc:02:01:33"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro51-sshminion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "minssh-slemicro51"
  image              = "slemicro51-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:46"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro52-sshminion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "minssh-slemicro52"
  image              = "slemicro52-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:47"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro53-sshminion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "minssh-slemicro53"
  image              = "slemicro53-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:48"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro54-sshminion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "minssh-slemicro54"
  image              = "slemicro54-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:49"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro55-sshminion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "head"
  name               = "minssh-slemicro55"
  image              = "slemicro55-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:4a"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp5-buildhost" {
  providers = {
    libvirt = libvirt.hugo
  }
  source             = "./modules/build_host"
  base_configuration = module.base_retail.configuration
  product_version    = "head"
  name               = "build-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:04"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp5-terminal" {
  providers = {
    libvirt = libvirt.hugo
  }
  source             = "./modules/pxe_boot"
  base_configuration = module.base_retail.configuration
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
  providers = {
    libvirt = libvirt.hugo
  }
  source             = "./modules/build_host"
  base_configuration = module.base_retail.configuration
  product_version    = "head"
  name               = "build-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:05"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4-terminal" {
  providers = {
    libvirt = libvirt.hugo
  }
  source             = "./modules/pxe_boot"
  base_configuration = module.base_retail.configuration
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
  providers = {
    libvirt = libvirt.hugo
  }
  source             = "./modules/minion"
  base_configuration = module.base_retail.configuration
  product_version    = "head"
  name               = "monitoring"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:03"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.prv.suse.net"
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
    mac                = "aa:b2:92:42:00:00"
    memory             = 16384
    vcpu               = 8
  }
  swap_file_size = null

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration = module.server_containerized.configuration

// WORKAROUND: We do the initial testing without a proxy and add it later
//  proxy_configuration  = module.proxy.configuration

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

  liberty9_minion_configuration    = module.liberty9-minion.configuration
  liberty9_sshminion_configuration = module.liberty9-sshminion.configuration

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

  debian11_minion_configuration    = module.debian11-minion.configuration
  debian11_sshminion_configuration = module.debian11-sshminion.configuration

  debian12_minion_configuration    = module.debian12-minion.configuration
  debian12_sshminion_configuration = module.debian12-sshminion.configuration

// WORKAROUND: overdrive3 will be replaced with a new ARM server
//  opensuse154arm_minion_configuration    = module.opensuse154arm-minion.configuration
//  opensuse154arm_sshminion_configuration = module.opensuse154arm-sshminion.configuration
//
//  opensuse155arm_minion_configuration    = module.opensuse155arm-minion.configuration
//  opensuse155arm_sshminion_configuration = module.opensuse155arm-sshminion.configuration

  sle15sp5s390_minion_configuration    = module.sles15sp5s390-minion.configuration
  sle15sp5s390_sshminion_configuration = module.sles15sp5s390-sshminion.configuration

  slemicro51_minion_configuration    = module.slemicro51-minion.configuration
  slemicro51_sshminion_configuration = module.slemicro51-sshminion.configuration

  slemicro52_minion_configuration    = module.slemicro52-minion.configuration
  slemicro52_sshminion_configuration = module.slemicro52-sshminion.configuration

  slemicro53_minion_configuration    = module.slemicro53-minion.configuration
  slemicro53_sshminion_configuration = module.slemicro53-sshminion.configuration

  slemicro54_minion_configuration    = module.slemicro54-minion.configuration
  slemicro54_sshminion_configuration = module.slemicro54-sshminion.configuration

  slemicro55_minion_configuration    = module.slemicro55-minion.configuration
  slemicro55_sshminion_configuration = module.slemicro55-sshminion.configuration

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
