// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Manager-4.2/job/manager-4.2-qa-build-validation"
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
  default = "Manager-4.2"
}

variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results 4.2 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results 4.2 Build Validation: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = "string"
  default = "galaxy-noise@suse.de"
}

variable "MAIL_TO" {
  type = "string"
  default = "galaxy-noise@suse.de"
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
  uri = "qemu+tcp://caladan.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "tatooine"
  uri = "qemu+tcp://tatooine.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "florina"
  uri = "qemu+tcp://florina.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "terminus"
  uri = "qemu+tcp://terminus.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "trantor"
  uri = "qemu+tcp://trantor.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "overdrive4"
  uri = "qemu+tcp://overdrive4.arch.suse.de/system"
}

module "base_core" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-42-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles15sp3o", "opensuse152o" ]

  mirror = "minima-mirror-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
    additional_network = "192.168.42.0/24"
  }
}

module "base_old_sle" {
  providers = {
    libvirt = libvirt.tatooine
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-42-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles11sp4", "sles12sp4o", "sles12sp5o" ]

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
    libvirt = libvirt.tatooine
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-42-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "centos7o", "centos8o" ]

  mirror = "minima-mirror-bv2.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

module "base_new_sle" {
  providers = {
    libvirt = libvirt.florina
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-42-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles15o", "sles15sp1o", "sles15sp2o", "sles15sp3o" ]

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
    libvirt = libvirt.terminus
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-42-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "opensuse152o", "sles11sp4", "sles12sp4o", "sles15sp2o", "sles15sp3o" ]

  mirror = "minima-mirror-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
    additional_network = "192.168.42.0/24"
  }
}

module "base_debian" {
  providers = {
    libvirt = libvirt.trantor
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-42-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "ubuntu1804o", "ubuntu2004o", "debian9o", "debian10o" ]

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
  name_prefix = "suma-bv-42-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "opensuse153armo" ]

  mirror = "minima-mirror-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br0"
  }
}

module "server" {
  source             = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version    = "4.2-released"
  name               = "srv"
  provider_settings = {
    mac                = "aa:b2:92:42:00:89"
    memory             = 40960
    vcpu               = 10
    data_pool          = "ssd"
  }

  server_mounted_mirror = "minima-mirror-bv.mgr.prv.suse.net"
  repository_disk_size = 1500

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

  //server_additional_repos

}

module "proxy" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/proxy"
  base_configuration = module.base_retail.configuration
  product_version    = "4.2-released"
  name               = "pxy"
  provider_settings = {
    mac                = "aa:b2:92:42:00:8a"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-srv.mgr.prv.suse.net"
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

  //proxy_additional_repos

}

module "sles11sp4-client" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/client"
  base_configuration = module.base_old_sle.configuration
  product_version    = "4.2-released"
  name               = "cli-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "aa:b2:92:42:00:90"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle11sp4-client_additional_repos

}

module "sles12sp4-client" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/client"
  base_configuration = module.base_old_sle.configuration
  product_version    = "4.2-released"
  name               = "cli-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:91"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle12sp4-client_additional_repos

}

module "sles12sp5-client" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/client"
  base_configuration = module.base_old_sle.configuration
  product_version    = "4.2-released"
  name               = "cli-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:92"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle12sp5-client_additional_repos

}

module "sles15-client" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  product_version    = "4.2-released"
  name               = "cli-sles15"
  image              = "sles15o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:93"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15-client_additional_repos

}

module "sles15sp1-client" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  product_version    = "4.2-released"
  name               = "cli-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:94"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp1-client_additional_repos

}

module "sles15sp2-client" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  product_version    = "4.2-released"
  name               = "cli-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:95"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp2-client_additional_repos

}

module "sles15sp3-client" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  product_version    = "4.2-released"
  name               = "cli-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:96"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp3-client_additional_repos

}

module "centos7-client" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/client"
  base_configuration = module.base_res.configuration
  product_version    = "4.2-released"
  name               = "cli-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:97"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_register = false
  use_os_released_updates = false
  ssh_key_path  = "./salt/controller/id_rsa.pub"

  //ceos7-client_additional_repos

}

module "sles11sp4-minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "4.2-released"
  name               = "min-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a0"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle11sp4-minion_additional_repos

}

module "sles12sp4-minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "4.2-released"
  name               = "min-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a1"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle12sp4-minion_additional_repos

}

module "sles12sp5-minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "4.2-released"
  name               = "min-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a2"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle12sp5-minion_additional_repos

}

module "sles15-minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "4.2-released"
  name               = "min-sles15"
  image              = "sles15o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a3"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15-minion_additional_repos

}

module "sles15sp1-minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "4.2-released"
  name               = "min-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a4"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp1-minion_additional_repos

}

module "sles15sp2-minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "4.2-released"
  name               = "min-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a5"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp2-minion_additional_repos

}

module "sles15sp3-minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "4.2-released"
  name               = "min-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a6"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp3-minion_additional_repos

}

module "centos7-minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "4.2-released"
  name               = "min-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a7"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master = false
  use_os_released_updates = false
  ssh_key_path           = "./salt/controller/id_rsa.pub"

  //ceos7-minion_additional_repos

}

module "centos8-minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "4.2-released"
  name               = "min-centos8"
  image              = "centos8o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a8"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master = false
  use_os_released_updates = false
  ssh_key_path           = "./salt/controller/id_rsa.pub"

  //ceos8-minion_additional_repos

}

module "ubuntu1804-minion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "4.2-released"
  name               = "min-ubuntu1804"
  image              = "ubuntu1804o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a9"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master = false
  use_os_released_updates = false
  ssh_key_path           = "./salt/controller/id_rsa.pub"

  //ubuntu1804-minion_additional_repos

}

module "ubuntu2004-minion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "4.2-released"
  name               = "min-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:aa"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master = false
  use_os_released_updates = false
  ssh_key_path           = "./salt/controller/id_rsa.pub"

  //ubuntu2004-minion_additional_repos

}

module "debian9-minion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "4.2-released"
  name               = "min-debian9"
  image              = "debian9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:ab"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //debian9-minion_additional_repos

}

module "debian10-minion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "4.2-released"
  name               = "min-debian10"
  image              = "debian10o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:ac"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //debian10-minion_additional_repos

}

module "sles11sp4-sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "4.2-released"
  name               = "minssh-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b0"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp4-sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "4.2-released"
  name               = "minssh-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b1"
    memory             = 4096
  }

  use_os_released_updates = false
  ssh_key_path = "./salt/controller/id_rsa.pub"
  gpg_keys     = ["default/gpg_keys/galaxy.key"]
}

module "sles12sp5-sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "4.2-released"
  name               = "minssh-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b2"
    memory             = 4096
  }

  use_os_released_updates = false
  ssh_key_path = "./salt/controller/id_rsa.pub"
  gpg_keys     = ["default/gpg_keys/galaxy.key"]
}

module "sles15-sshminion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "4.2-released"
  name               = "minssh-sles15"
  image              = "sles15o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b3"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

}

module "sles15sp1-sshminion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "4.2-released"
  name               = "minssh-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b4"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

}

module "sles15sp2-sshminion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "4.2-released"
  name               = "minssh-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b5"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp3-sshminion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "4.2-released"
  name               = "minssh-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b6"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "centos7-sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "4.2-released"
  name               = "minssh-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b7"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path = "./salt/controller/id_rsa.pub"
}

module "centos8-sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "4.2-released"
  name               = "minssh-centos8"
  image              = "centos8o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b8"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path = "./salt/controller/id_rsa.pub"
}

module "ubuntu1804-sshminion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "4.2-released"
  name               = "minssh-ubuntu1804"
  image              = "ubuntu1804o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b9"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path       = "./salt/controller/id_rsa.pub"
}

module "ubuntu2004-sshminion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "4.2-released"
  name               = "minssh-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:ba"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path       = "./salt/controller/id_rsa.pub"
}

module "debian9-sshminion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "4.2-released"
  name               = "minssh-debian9"
  image              = "debian9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:bb"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian10-sshminion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "4.2-released"
  name               = "minssh-debian10"
  image              = "debian10o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:bc"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles11sp4-buildhost" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/minion"
  base_configuration = module.base_retail.configuration
  product_version    = "4.2-released"
  name               = "build-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "aa:b2:92:42:00:c0"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles11sp3-terminal" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/minion"
  base_configuration = module.base_retail.configuration
  product_version    = "4.2-released"
  name               = "terminal-sles11sp4"
  image              = "sles11sp4" # This is not a typo
  provider_settings = {
    memory             = 1024
    vcpu               = 1
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp4-buildhost" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/minion"
  base_configuration = module.base_retail.configuration
  product_version    = "4.2-released"
  name               = "build-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:c1"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp4-terminal" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/minion"
  base_configuration = module.base_retail.configuration
  product_version    = "4.2-released"
  name               = "terminal-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    memory             = 1024
    vcpu               = 1
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp2-buildhost" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/minion"
  base_configuration = module.base_retail.configuration
  product_version    = "4.2-released"
  name               = "build-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:c3"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp2-terminal" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/minion"
  base_configuration = module.base_retail.configuration
  product_version    = "4.2-released"
  name               = "terminal-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "opensuse153arm-minion" {
  providers = {
    libvirt = libvirt.overdrive4
  }
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  product_version    = "4.2-released"
  name               = "min-opensuse153arm"
  image              = "opensuse153armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:ad"
    memory             = 2048
    vcpu               = 2
    xslt               = <<EOT
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- XSL transformation for aarch64 -->

  <xsl:output omit-xml-declaration="yes" />

  <!-- no IDE on aarch64, use SCSI instead -->
  <xsl:template match="@bus[.='ide']">
    <xsl:attribute name="bus"> <xsl:text>scsi</xsl:text> </xsl:attribute>
  </xsl:template>

  <!-- provide flash for booting -->
  <xsl:template match="os">
    <xsl:copy>
      <xsl:apply-templates select="*|@*" />
      <xsl:element name="loader">
        <xsl:attribute name="type"> <xsl:text>pflash</xsl:text> </xsl:attribute>
        <xsl:attribute name="readonly"> <xsl:text>yes</xsl:text> </xsl:attribute>
        <xsl:text>/usr/share/qemu/aavmf-aarch64-code.bin</xsl:text>
      </xsl:element>
    </xsl:copy>
  </xsl:template>

  <!-- change machine type -->
  <xsl:template match="type">
    <xsl:element name="type">
      <xsl:attribute name="machine"> <xsl:text>virt</xsl:text> </xsl:attribute>
      <xsl:text>hvm</xsl:text>
    </xsl:element>
  </xsl:template>

  <!-- use host passthrough mode for CPU -->
  <xsl:template match="cpu">
    <xsl:element name="cpu">
      <xsl:attribute name="mode"> <xsl:text>host-passthrough</xsl:text> </xsl:attribute>
      <xsl:attribute name="check"> <xsl:text>none</xsl:text> </xsl:attribute>
    </xsl:element>
  </xsl:template>

  <!-- work around https://gitlab.com/libvirt/libvirt/-/issues/177
       for <controller type="virtio-serial"> -->
  <!-- no LSI logic on aarch64, use virtio-scsi instead -->
  <xsl:template match="devices">
    <xsl:copy>
      <xsl:apply-templates select="*|@*" />
      <xsl:element name="controller">
        <xsl:attribute name="type"> <xsl:text>virtio-serial</xsl:text> </xsl:attribute>
        <xsl:element name="address">
          <xsl:attribute name="type"> <xsl:text>virtio-mmio</xsl:text> </xsl:attribute>
        </xsl:element>
      </xsl:element>
      <xsl:element name="controller">
        <xsl:attribute name="type"> <xsl:text>scsi</xsl:text> </xsl:attribute>
        <xsl:attribute name="model"> <xsl:text>virtio-scsi</xsl:text> </xsl:attribute>
        <xsl:element name="address">
          <xsl:attribute name="type"> <xsl:text>virtio-mmio</xsl:text> </xsl:attribute>
        </xsl:element>
      </xsl:element>
    </xsl:copy>
  </xsl:template>

  <!-- work around https://gitlab.com/libvirt/libvirt/-/issues/177
       for <disk type="volume"> -->
  <xsl:template match="disk[@type='volume']">
    <xsl:copy>
      <xsl:apply-templates select="*|@*" />
      <xsl:element name="address">
        <xsl:attribute name="type"> <xsl:text>virtio-mmio</xsl:text> </xsl:attribute>
      </xsl:element>
    </xsl:copy>
  </xsl:template>

  <!-- work around https://gitlab.com/libvirt/libvirt/-/issues/177
       for <rng> -->
  <xsl:template match="rng" />

  <!-- just copy the rest -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
EOT
  }
  server_configuration = {
    hostname = "suma-bv-42-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp3arm-minion_additional_repos

}

module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base_core.configuration
  name               = "ctl"
  provider_settings = {
    mac                = "aa:b2:92:42:00:88"
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

  centos7_client_configuration    = module.centos7-client.configuration
  centos7_minion_configuration    = module.centos7-minion.configuration
  centos7_sshminion_configuration = module.centos7-sshminion.configuration

  centos8_minion_configuration    = module.centos8-minion.configuration
  centos8_sshminion_configuration = module.centos8-sshminion.configuration

  sle11sp4_client_configuration    = module.sles11sp4-client.configuration
  sle11sp4_minion_configuration    = module.sles11sp4-minion.configuration
  sle11sp4_sshminion_configuration = module.sles11sp4-sshminion.configuration

  sle12sp4_client_configuration    = module.sles12sp4-client.configuration
  sle12sp4_minion_configuration    = module.sles12sp4-minion.configuration
  sle12sp4_sshminion_configuration = module.sles12sp4-sshminion.configuration

  sle12sp5_client_configuration    = module.sles12sp5-client.configuration
  sle12sp5_minion_configuration    = module.sles12sp5-minion.configuration
  sle12sp5_sshminion_configuration = module.sles12sp5-sshminion.configuration

  sle15_client_configuration    = module.sles15-client.configuration
  sle15_minion_configuration    = module.sles15-minion.configuration
  sle15_sshminion_configuration = module.sles15-sshminion.configuration

  sle15sp1_client_configuration    = module.sles15sp1-client.configuration
  sle15sp1_minion_configuration    = module.sles15sp1-minion.configuration
  sle15sp1_sshminion_configuration = module.sles15sp1-sshminion.configuration

  sle15sp2_client_configuration    = module.sles15sp2-client.configuration
  sle15sp2_minion_configuration    = module.sles15sp2-minion.configuration
  sle15sp2_sshminion_configuration = module.sles15sp2-sshminion.configuration

  sle15sp3_client_configuration    = module.sles15sp3-client.configuration
  sle15sp3_minion_configuration    = module.sles15sp3-minion.configuration
  sle15sp3_sshminion_configuration = module.sles15sp3-sshminion.configuration

  ubuntu1804_minion_configuration    = module.ubuntu1804-minion.configuration
  ubuntu1804_sshminion_configuration = module.ubuntu1804-sshminion.configuration

  ubuntu2004_minion_configuration    = module.ubuntu2004-minion.configuration
  ubuntu2004_sshminion_configuration = module.ubuntu2004-sshminion.configuration

  debian9_minion_configuration    = module.debian9-minion.configuration
  debian9_sshminion_configuration = module.debian9-sshminion.configuration

  debian10_minion_configuration    = module.debian10-minion.configuration
  debian10_sshminion_configuration = module.debian10-sshminion.configuration

  sle11sp4_buildhost_configuration = module.sles11sp4-buildhost.configuration
  sle12sp4_buildhost_configuration = module.sles12sp4-buildhost.configuration
  sle15sp2_buildhost_configuration = module.sles15sp2-buildhost.configuration

  sle11sp3_terminal_configuration = module.sles11sp3-terminal.configuration
  sle12sp4_terminal_configuration = module.sles12sp4-terminal.configuration
  sle15sp2_terminal_configuration = module.sles15sp2-terminal.configuration

  opensuse153arm_minion_configuration = module.opensuse153arm-minion.configuration
}

resource "null_resource" "server_extra_nfs_mounts" {
  provisioner "remote-exec" {
    inline = [
      "echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/repo/$RCE/RES7  /mirror/repo/$RCE/RES7  nfs  defaults  0 0' >> /etc/fstab",
      "mount '/mirror/repo/$RCE/RES7'",
      "echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/repo/$RCE/RES7-SUSE-Manager-Tools  /mirror/repo/$RCE/RES7-SUSE-Manager-Tools  nfs  defaults  0 0' >> /etc/fstab",
      "mount '/mirror/repo/$RCE/RES7-SUSE-Manager-Tools'",
      "echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/repo/$RCE/RES7-SUSE-Manager-Tools-Beta  /mirror/repo/$RCE/RES7-SUSE-Manager-Tools-Beta  nfs  defaults  0 0' >> /etc/fstab",
      "mount '/mirror/repo/$RCE/RES7-SUSE-Manager-Tools-Beta'",
      "echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/SUSE/Updates/RES  /mirror/SUSE/Updates/RES  nfs  defaults  0 0' >> /etc/fstab",
      "mount '/mirror/SUSE/Updates/RES'",
      "echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/SUSE/Updates/RES-CB  /mirror/SUSE/Updates/RES-CB  nfs  defaults  0 0' >> /etc/fstab",
      "mount '/mirror/SUSE/Updates/RES-CB'",
      "echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/SUSE/Updates/RES-AS  /mirror/SUSE/Updates/RES-AS  nfs  defaults  0 0' >> /etc/fstab",
      "mount '/mirror/SUSE/Updates/RES-AS'",
      "echo 'minima-mirror-bv2.mgr.prv.suse.net:/srv/mirror/SUSE/Products/RES  /mirror/SUSE/Products/RES  nfs  defaults  0 0' >> /etc/fstab",
      "mount '/mirror/SUSE/Products/RES'"
    ]
    connection {
      type     = "ssh"
      user     = "root"
      password = "linux"
      host     = "${module.server.configuration.hostname}"
    }
  }
}

output "configuration" {
  value = {
    controller = module.controller.configuration
  }
}
