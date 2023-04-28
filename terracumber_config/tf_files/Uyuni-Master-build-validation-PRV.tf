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

provider "libvirt" {
  alias = "overdrive4"
  uri = "qemu+tcp://overdrive4.mgr.suse.de/system"
}

module "base_core" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles15sp4o", "opensuse154o" ]

  mirror = "minima-mirror-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
    additional_network = "192.168.43.0/24"
  }
}

module "base_old_sle" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles12sp4o", "sles12sp5o" ]

  mirror = "minima-mirror-bv.mgr.prv.suse.net"
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
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "almalinux9o", "centos7o", "libertylinux9o", "oraclelinux9o", "rocky8o", "rocky9o" ]

  mirror = "minima-mirror-bv.mgr.prv.suse.net"
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
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles15sp1o", "sles15sp2o", "sles15sp3o", "sles15sp4o", "slemicro51-ign", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign"  ]

  mirror = "minima-mirror-bv.mgr.prv.suse.net"
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
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles12sp5o", "sles15sp3o", "sles15sp4o", "opensuse154o" ]

  mirror = "minima-mirror-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
    additional_network = "192.168.43.0/24"
  }
}

module "base_debian" {
  providers = {
    libvirt = libvirt.irishcoffee
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "ubuntu1804o", "ubuntu2004o", "ubuntu2204o", "debian10o", "debian11o" ]

  mirror = "minima-mirror-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

module "base_arm" {
  providers = {
    libvirt = libvirt.overdrive4
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "opensuse154armo" ]

  mirror = "minima-mirror-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

module "server" {
  source             = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-released"
  name               = "srv"
  provider_settings = {
    mac                = "aa:b2:93:02:01:6d"
    memory             = 40960
    vcpu               = 10
    data_pool          = "ssd"
  }

  server_mounted_mirror = "minima-mirror-bv.mgr.prv.suse.net"
  repository_disk_size = 1700

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
  ssh_key_path                   = "./salt/controller/id_rsa.pub"
  from_email                     = "root@suse.de"
  accept_all_ssl_protocols       = true

  //server_additional_repos

}

module "proxy" {
  providers = {
    libvirt = libvirt.hugo
  }
  source             = "./modules/proxy"
  base_configuration = module.base_retail.configuration
  product_version    = "uyuni-released"
  name               = "pxy"
  provider_settings = {
    mac                = "aa:b2:93:02:01:6e"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-srv.mgr.prv.suse.net"
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

module "sles12sp4-client" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/client"
  base_configuration = module.base_old_sle.configuration
  product_version    = "uyuni-released"
  name               = "cli-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:74"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp5-client" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/client"
  base_configuration = module.base_old_sle.configuration
  product_version    = "uyuni-released"
  name               = "cli-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:75"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp1-client" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  product_version    = "uyuni-released"
  name               = "cli-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:77"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp2-client" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  product_version    = "uyuni-released"
  name               = "cli-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:78"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp3-client" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  product_version    = "uyuni-released"
  name               = "cli-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:79"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4-client" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  product_version    = "uyuni-released"
  name               = "cli-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:7a"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "centos7-client" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/client"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-released"
  name               = "cli-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:7b"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles12sp4-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "uyuni-released"
  name               = "min-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:7c"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp5-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "uyuni-released"
  name               = "min-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:7d"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-released"
  name               = "min-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:7f"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-released"
  name               = "min-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:80"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-released"
  name               = "min-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:81"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-released"
  name               = "min-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:82"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-released"
  name               = "min-alma9"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:8e"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "centos7-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-released"
  name               = "min-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:83"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-released"
  name               = "min-liberty9"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:91"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "oracle9-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-released"
  name               = "min-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:8f"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "rocky8-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-released"
  name               = "min-rocky8"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:84"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "rocky9-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-released"
  name               = "min-rocky9"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:8d"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu1804-minion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-released"
  name               = "min-ubuntu1804"
  image              = "ubuntu1804o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:85"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu2004-minion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-released"
  name               = "min-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:86"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu2204-minion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-released"
  name               = "min-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:87"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

// Debian 9 is not supported by 4.3

module "debian10-minion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-released"
  name               = "min-debian10"
  image              = "debian10o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:89"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-released"
  name               = "min-debian11"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:8a"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "opensuse154arm-minion" {
  providers = {
    libvirt = libvirt.overdrive4
  }
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  product_version    = "uyuni-released"
  name               = "min-opensuse154arm"
  image              = "opensuse154armo"
  provider_settings = {
    mac                = "aa:b2:93:01:00:f8"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro51-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "uyuni-released"
  name               = "min-slemicro51"
  image              = "slemicro51-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:92"
   memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-released"
  name               = "min-slemicro52"
  image              = "slemicro52-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:8c"
   memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-released"
  name               = "min-slemicro53"
  image              = "slemicro53-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:90"
   memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-released"
  name               = "min-slemicro54"
  image              = "slemicro54-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:7e"
   memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp4-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "uyuni-released"
  name               = "minssh-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:9c"
    memory             = 4096
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]
}

module "sles12sp5-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "uyuni-released"
  name               = "minssh-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:9d"
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
  product_version    = "uyuni-released"
  name               = "minssh-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:9f"
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
  product_version    = "uyuni-released"
  name               = "minssh-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a0"
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
  product_version    = "uyuni-released"
  name               = "minssh-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a1"
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
  product_version    = "uyuni-released"
  name               = "minssh-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a2"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "alma9-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-released"
  name               = "minssh-alma9"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:ae"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "centos7-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-released"
  name               = "minssh-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a3"
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
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-released"
  name               = "minssh-liberty9"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b1"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "oracle9-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-released"
  name               = "minssh-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:af"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "rocky8-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-released"
  name               = "minssh-rocky8"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a4"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "rocky9-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-released"
  name               = "minssh-rocky9"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:ad"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu1804-sshminion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-released"
  name               = "minssh-ubuntu1804"
  image              = "ubuntu1804o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a5"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu2004-sshminion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-released"
  name               = "minssh-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a6"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu2204-sshminion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-released"
  name               = "minssh-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a7"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

// Debian 9 is not supported by 4.3

module "debian10-sshminion" {
  providers = {
    libvirt = libvirt.irishcoffee
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-released"
  name               = "minssh-debian10"
  image              = "debian10o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a9"
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
  product_version    = "uyuni-released"
  name               = "minssh-debian11"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:aa"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "opensuse154arm-sshminion" {
  providers = {
    libvirt = libvirt.overdrive4
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_arm.configuration
  product_version    = "uyuni-released"
  name               = "minssh-opensuse154arm"
  image              = "opensuse154armo"
  provider_settings = {
    mac                = "aa:b2:93:01:00:f9"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
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
  product_version    = "uyuni-released"
  name               = "minssh-slemicro51"
  image              = "slemicro51-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b2"
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
  product_version    = "uyuni-released"
  name               = "minssh-slemicro52"
  image              = "slemicro52-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:ac"
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
  product_version    = "uyuni-released"
  name               = "minssh-slemicro53"
  image              = "slemicro53-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b0"
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
  product_version    = "uyuni-released"
  name               = "minssh-slemicro54"
  image              = "slemicro54-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:9e"
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
  product_version    = "uyuni-released"
  name               = "build-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:70"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-released"
  name               = "build-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:71"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-released"
  name               = "monitoring"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:6f"
    memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
    mac                = "aa:b2:93:02:01:6c"
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

  sle12sp4_client_configuration    = module.sles12sp4-client.configuration
  sle12sp4_minion_configuration    = module.sles12sp4-minion.configuration
  sle12sp4_sshminion_configuration = module.sles12sp4-sshminion.configuration

  sle12sp5_client_configuration    = module.sles12sp5-client.configuration
  sle12sp5_minion_configuration    = module.sles12sp5-minion.configuration
  sle12sp5_sshminion_configuration = module.sles12sp5-sshminion.configuration

  sle15sp1_client_configuration    = module.sles15sp1-client.configuration
  sle15sp1_minion_configuration    = module.sles15sp1-minion.configuration
  sle15sp1_sshminion_configuration = module.sles15sp1-sshminion.configuration

  sle15sp2_client_configuration    = module.sles15sp2-client.configuration
  sle15sp2_minion_configuration    = module.sles15sp2-minion.configuration
  sle15sp2_sshminion_configuration = module.sles15sp2-sshminion.configuration

  sle15sp3_client_configuration    = module.sles15sp3-client.configuration
  sle15sp3_minion_configuration    = module.sles15sp3-minion.configuration
  sle15sp3_sshminion_configuration = module.sles15sp3-sshminion.configuration

  sle15sp4_client_configuration    = module.sles15sp4-client.configuration
  sle15sp4_minion_configuration    = module.sles15sp4-minion.configuration
  sle15sp4_sshminion_configuration = module.sles15sp4-sshminion.configuration

  alma9_minion_configuration    = module.alma9-minion.configuration
  alma9_sshminion_configuration = module.alma9-sshminion.configuration

  centos7_client_configuration    = module.centos7-client.configuration
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

  ubuntu1804_minion_configuration    = module.ubuntu1804-minion.configuration
  ubuntu1804_sshminion_configuration = module.ubuntu1804-sshminion.configuration

  ubuntu2004_minion_configuration    = module.ubuntu2004-minion.configuration
  ubuntu2004_sshminion_configuration = module.ubuntu2004-sshminion.configuration

  ubuntu2204_minion_configuration    = module.ubuntu2204-minion.configuration
  ubuntu2204_sshminion_configuration = module.ubuntu2204-sshminion.configuration

  debian10_minion_configuration    = module.debian10-minion.configuration
  debian10_sshminion_configuration = module.debian10-sshminion.configuration

  debian11_minion_configuration    = module.debian11-minion.configuration
  debian11_sshminion_configuration = module.debian11-sshminion.configuration

  opensuse154arm_minion_configuration    = module.opensuse154arm-minion.configuration
  opensuse154arm_sshminion_configuration = module.opensuse154arm-sshminion.configuration

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
