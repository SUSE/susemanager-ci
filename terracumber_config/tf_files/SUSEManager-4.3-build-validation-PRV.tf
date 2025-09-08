// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-4.3/job/manager-4.3-qe-build-validation"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = string
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = string
  default = "https://github.com/SUSE/spacewalk.git"
}

variable "CUCUMBER_BRANCH" {
  type = string
  default = "Manager-4.3"
}

variable "CUCUMBER_RESULTS" {
  type = string
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = string
  default = "Results 4.3 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results 4.3 Build Validation: Environment setup failed"
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
      version = "0.8.1"
    }
    feilong = {
      source = "bischoff/feilong"
      version = "0.0.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://arrakis.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "endor"
  uri = "qemu+tcp://endor.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "moscowmule"
  uri = "qemu+tcp://moscowmule.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "coruscant"
  uri = "qemu+tcp://coruscant.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "mandalore"
  uri = "qemu+tcp://mandalore.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "suma-arm"
  uri = "qemu+tcp://suma-arm.mgr.suse.de/system"
}

provider "feilong" {
  connector   = "https://feilong.mgr.suse.de"
  admin_token = var.ZVM_ADMIN_TOKEN
  local_user  = "jenkins@jenkins-worker.mgr.prv.suse.net"
}

module "base_core" {
  source            = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = "4.3-released"
  name_prefix       = "suma-bv-43-"
  use_avahi         = false
  domain            = "mgr.prv.suse.net"
  images            = [ "sles15sp4o", "opensuse155o" ]

  mirror            = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

module "base_old_sle" {
  providers = {
    libvirt = libvirt.endor
  }

  source            = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = "4.3-released"
  name_prefix       = "suma-bv-43-"
  use_avahi         = false
  domain            = "mgr.prv.suse.net"
  images            = [ "sles12sp5o" ]

  mirror            = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite         = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

module "base_res" {
  providers = {
    libvirt = libvirt.endor
  }

  source            = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = "4.3-released"
  name_prefix       = "suma-bv-43-"
  use_avahi         = false
  domain            = "mgr.prv.suse.net"
  images            = [ "almalinux8o", "almalinux9o", "centos7o", "libertylinux9o", "oraclelinux9o", "rocky8o", "rocky9o" ]

  mirror            = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite         = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

module "base_new_sle" {
  providers = {
    libvirt = libvirt.moscowmule
  }

  source            = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = "4.3-released"
  name_prefix       = "suma-bv-43-"
  use_avahi         = false
  domain            = "mgr.prv.suse.net"
  images            = [ "sles15sp3o", "sles15sp4o", "sles15sp5o", "sles15sp6o", "sles15sp7o", "slemicro51-ign", "slemicro52-ign", "slemicro53-ign" , "slemicro54-ign", "slemicro55o", "slmicro60o", "slmicro61o" ]

  mirror            = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite         = true

  provider_settings = {
    pool        = "default"
    bridge      = "br1"
  }
}

module "base_retail" {
  providers = {
    libvirt = libvirt.coruscant
  }

  source            = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = "4.3-released"
  name_prefix       = "suma-bv-43-"
  use_avahi         = false
  domain            = "mgr.prv.suse.net"
  images            = [ "sles12sp5o", "sles15sp4o"]

  mirror            = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite         = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
    additional_network = "192.168.43.0/24"
  }
}

module "base_debian" {
  providers = {
    libvirt = libvirt.mandalore
  }

  source            = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = "4.3-released"
  name_prefix       = "suma-bv-43-"
  use_avahi         = false
  domain            = "mgr.prv.suse.net"
  images            = [ "ubuntu2004o", "ubuntu2204o", "ubuntu2404", "debian12o" ]

  mirror            = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite         = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

module "base_arm" {
  providers = {
    libvirt = libvirt.suma-arm
  }

  source            = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = "4.3-released"
  name_prefix       = "suma-bv-43-"
  use_avahi         = false
  domain            = "mgr.prv.suse.net"
  images            = [ "opensuse156armo" ]

  mirror            = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite         = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br0"
  }
}

module "base_s390" {
  source            = "./backend_modules/feilong/base"

  name_prefix       = "suma-bv-43-"
  domain            = "mgr.prv.suse.net"
  product_version   = "4.3-released"

  testsuite         = true
}

module "server" {
  source             = "./modules/server"
  base_configuration = module.base_core.configuration
  name               = "server"
  provider_settings = {
    mac                = "aa:b2:92:05:00:a1"
    memory             = 40960
    vcpu               = 10
    data_pool          = "ssd"
  }

  server_mounted_mirror          = "minima-mirror-ci-bv.mgr.prv.suse.net"
  main_disk_size                 = 20
  repository_disk_size           = 3072
  database_disk_size             = 150
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
  large_deployment               = true
  ssh_key_path                   = "./salt/controller/id_ed25519.pub"
  from_email                     = "root@suse.de"
  accept_all_ssl_protocols       = true

  //server_additional_repos

}

module "proxy" {
  providers = {
    libvirt = libvirt.coruscant
  }
  source             = "./modules/proxy"
  base_configuration = module.base_retail.configuration
  name               = "proxy"
  provider_settings = {
    mac                = "aa:b2:92:05:00:a2"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-server.mgr.prv.suse.net"
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
  ssh_key_path              = "./salt/controller/id_ed25519.pub"
}

module "sle12sp5_client" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/client"
  base_configuration = module.base_old_sle.configuration
  name               = "sles12sp5-client"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:a8"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp3_client" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp3-client"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:a9"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp4_client" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp4-client"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:aa"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp5_client" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp5-client"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:ab"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp6_client" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp6-client"
  image              = "sles15sp6o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:ac"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp7_client" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/client"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp7-client"
  image              = "sles15sp7o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:ad"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "centos7_client" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/client"
  base_configuration = module.base_res.configuration
  name               = "centos7-client"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:af"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sle12sp5_minion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/minion"
  base_configuration = module.base_old_sle.configuration
  name               = "sles12sp5-minion"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:b0"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp3_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp3-minion"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:b1"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp4_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp4-minion"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:b2"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp5_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp5-minion"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:b3"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp6_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp6-minion"
  image              = "sles15sp6o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:b4"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp7_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp7-minion"
  image              = "sles15sp7o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:b5"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "alma8_minion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  name               = "alma8-minion"
  image              = "almalinux8o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:b9"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "alma9_minion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  name               = "alma9-minion"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:c2"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "centos7_minion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  name               = "centos7-minion"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:b7"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "liberty9_minion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  name               = "liberty9-minion"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:c5"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "oracle9_minion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  name               = "oracle9-minion"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:c3"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky8_minion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  name               = "rocky8-minion"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:b8"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky9_minion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  name               = "rocky9-minion"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:c1"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2004_minion" {
  providers = {
    libvirt = libvirt.mandalore
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  name               = "ubuntu2004-minion"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:ba"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  # WORKAROUND https://github.com/uyuni-project/uyuni/issues/7637
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2204_minion" {
  providers = {
    libvirt = libvirt.mandalore
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  name               = "ubuntu2204-minion"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:bb"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "ubuntu2404_minion" {
  providers = {
    libvirt = libvirt.mandalore
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  name               = "ubuntu2404-minion"
  image              = "ubuntu2404o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:bd"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "debian12_minion" {
  providers = {
    libvirt = libvirt.mandalore
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  name               = "debian12-minion"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:bc"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "opensuse156arm_minion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  name               = "opensuse156arm-minion-prv"
  image              = "opensuse156armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:04"
    overwrite_fqdn     = "suma-bv-43-opensuse156arm-minion.mgr.prv.suse.net"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp5s390_minion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration

  name               = "sles15sp5s390-minion"
  image              = "s15s5-minimal-2part-xfs"

  provider_settings = {
    userid             = "S43MIPRV"
    mac                = "02:00:00:02:01:30"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

// This is an x86_64 SLES 15 SP5 minion (like sle15sp5_minion),
// dedicated to testing migration from OS Salt to Salt bundle
module "salt_migration_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "salt-migration-minion"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:cf"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = true
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  install_salt_bundle = false
}

module "slemicro51_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "slemicro51-minion"
  image              = "slemicro51-ign"
  provider_settings = {
    mac                = "aa:b2:92:05:00:c6"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  // WORKAROUND: Does not work in sumaform, yet
  //  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro52_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "slemicro52-minion"
  image              = "slemicro52-ign"
  provider_settings = {
    mac                = "aa:b2:92:05:00:c7"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  // WORKAROUND: Does not work in sumaform, yet
  //  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro53_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "slemicro53-minion"
  image              = "slemicro53-ign"
  provider_settings = {
    mac                = "aa:b2:92:05:00:c8"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  // WORKAROUND: Does not work in sumaform, yet
  //  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro54_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "slemicro54-minion"
  image              = "slemicro54-ign"
  provider_settings = {
    mac                = "aa:b2:92:05:00:c9"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  // WORKAROUND: Does not work in sumaform, yet
  //  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro55_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "slemicro55-minion"
  image              = "slemicro55o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:ca"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  // WORKAROUND: Does not work in sumaform, yet
  //  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slmicro60_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "slmicro60-minion"
  image              = "slmicro60o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:cb"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "slmicro61_minion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "slmicro61-minion"
  image              = "slmicro61o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:cc"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle12sp5_sshminion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_old_sle.configuration
  name               = "sles12sp5-sshminion"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:d0"
    memory             = 4096
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]
}

module "sle15sp3_sshminion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp3-sshminion"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:d1"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp4_sshminion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp4-sshminion"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:d2"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp5_sshminion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp5-sshminion"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:d3"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp6_sshminion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp6-sshminion"
  image              = "sles15sp6o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:d4"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp7_sshminion" {
  providers = {
    libvirt = libvirt.moscowmule
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  name               = "sles15sp7-sshminion"
  image              = "sles15sp7o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:d5"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "alma8_sshminion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  name               = "alma8-sshminion"
  image              = "almalinux8o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:d9"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "alma9_sshminion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  name               = "alma9-sshminion"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:e2"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "centos7_sshminion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  name               = "centos7-sshminion"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:d7"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "liberty9_sshminion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  name               = "liberty9-sshminion"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:e5"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "oracle9_sshminion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  name               = "oracle9-sshminion"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:e3"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky8_sshminion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  name               = "rocky8-sshminion"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:d8"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky9_sshminion" {
  providers = {
    libvirt = libvirt.endor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  name               = "rocky9-sshminion"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:e1"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2004_sshminion" {
  providers = {
    libvirt = libvirt.mandalore
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  name               = "ubuntu2004-sshminion"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:da"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  # WORKAROUND https://github.com/uyuni-project/uyuni/issues/7637
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2204_sshminion" {
  providers = {
    libvirt = libvirt.mandalore
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  name               = "ubuntu2204-sshminion"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:db"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "ubuntu2404_sshminion" {
  providers = {
    libvirt = libvirt.mandalore
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  name               = "ubuntu2404-sshminion"
  image              = "ubuntu2404o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:dd"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "debian12_sshminion" {
  providers = {
    libvirt = libvirt.mandalore
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  name               = "debian12-sshminion"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:dc"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "opensuse156arm_sshminion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_arm.configuration
  name               = "opensuse156arm-sshminion-prv"
  image              = "opensuse156armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:05"
    overwrite_fqdn     = "suma-bv-43-opensuse156arm-sshminion.mgr.prv.suse.net"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp5s390_sshminion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration

  name               = "sles15sp5s390-sshminion"
  image              = "s15s5-minimal-2part-xfs"

  provider_settings = {
    userid             = "S43SSPRV"
    mac                = "02:00:00:02:01:31"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro51_sshminion" {
//   providers = {
//     libvirt = libvirt.moscowmule
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   name               = "slemicro51-sshminion"
//   image              = "slemicro51-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:e6"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro52_sshminion" {
//   providers = {
//     libvirt = libvirt.moscowmule
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   name               = "slemicro52-sshminion"
//   image              = "slemicro52-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:e7"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro53_sshminion" {
//   providers = {
//     libvirt = libvirt.moscowmule
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   name               = "slemicro53-sshminion"
//   image              = "slemicro53-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:e8"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro54_sshminion" {
//  providers = {
//     libvirt = libvirt.moscowmule
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   name               = "slemicro54-sshminion"
//   image              = "slemicro54-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:e9"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro55_sshminion" {
//  providers = {
//     libvirt = libvirt.moscowmule
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   name               = "slemicro55-sshminion"
//   image              = "slemicro55o"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:ea"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slmicro60_sshminion" {
//  providers = {
//     libvirt = libvirt.moscowmule
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   name               = "slmicro60-sshminion"
//   image              = "slmicro60o"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:eb"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slmicro61_sshminion" {
//  providers = {
//     libvirt = libvirt.moscowmule
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   name               = "slmicro61-sshminion"
//   image              = "slmicro61o"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:ec"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
// }

module "sle12sp5_buildhost" {
  providers = {
    libvirt = libvirt.coruscant
  }
  source             = "./modules/build_host"
  base_configuration = module.base_retail.configuration
  name               = "sles12sp5-build"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:a4"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle12sp5_terminal" {
  providers = {
    libvirt = libvirt.coruscant
  }
  source             = "./modules/pxe_boot"
  base_configuration = module.base_retail.configuration
  name               = "sles12sp5-terminal"
  image              = "sles12sp5o"
  provider_settings = {
    memory             = 2048
    vcpu               = 1
    manufacturer       = "Supermicro"
    product            = "X9DR3-F"
  }
  private_ip         = 5
  private_name       = "sle12sp5terminal"
}

module "sle15sp4_buildhost" {
  providers = {
    libvirt = libvirt.coruscant
  }
  source             = "./modules/build_host"
  base_configuration = module.base_retail.configuration
  name               = "sles15sp4-build"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:a5"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sle15sp4_terminal" {
  providers = {
    libvirt = libvirt.coruscant
  }
  source             = "./modules/pxe_boot"
  base_configuration = module.base_retail.configuration
  name               = "sles15sp4-terminal"
  image              = "sles15sp4o"
  provider_settings = {
    memory             = 2048
    vcpu               = 2
    manufacturer       = "HP"
    product            = "ProLiant DL360 Gen9"
  }
  private_ip         = 6
  private_name       = "sle15sp4terminal"
}

module "monitoring-server" {
  providers = {
    libvirt = libvirt.coruscant
  }
  source             = "./modules/minion"
  base_configuration = module.base_retail.configuration
  name               = "monitoring"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:a3"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base_core.configuration
  name               = "controller"
  provider_settings = {
    mac                = "aa:b2:92:05:00:a0"
    memory             = 16384
    vcpu               = 8
  }
  swap_file_size = null
  catch_timeout_message = false

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration = module.server.configuration
  proxy_configuration  = module.proxy.configuration

  sle12sp5_client_configuration    = module.sle12sp5_client.configuration
  sle12sp5_minion_configuration    = module.sle12sp5_minion.configuration
  sle12sp5_sshminion_configuration = module.sle12sp5_sshminion.configuration

  sle15sp3_client_configuration    = module.sle15sp3_client.configuration
  sle15sp3_minion_configuration    = module.sle15sp3_minion.configuration
  sle15sp3_sshminion_configuration = module.sle15sp3_sshminion.configuration

  sle15sp4_client_configuration    = module.sle15sp4_client.configuration
  sle15sp4_minion_configuration    = module.sle15sp4_minion.configuration
  sle15sp4_sshminion_configuration = module.sle15sp4_sshminion.configuration

  sle15sp5_client_configuration    = module.sle15sp5_client.configuration
  sle15sp5_minion_configuration    = module.sle15sp5_minion.configuration
  sle15sp5_sshminion_configuration = module.sle15sp5_sshminion.configuration

  sle15sp6_client_configuration    = module.sle15sp6_client.configuration
  sle15sp6_minion_configuration    = module.sle15sp6_minion.configuration
  sle15sp6_sshminion_configuration = module.sle15sp6_sshminion.configuration

  sle15sp7_client_configuration    = module.sle15sp7_client.configuration
  sle15sp7_minion_configuration    = module.sle15sp7_minion.configuration
  sle15sp7_sshminion_configuration = module.sle15sp7_sshminion.configuration

  alma8_minion_configuration    = module.alma8_minion.configuration
  alma8_sshminion_configuration = module.alma8_sshminion.configuration

  alma9_minion_configuration    = module.alma9_minion.configuration
  alma9_sshminion_configuration = module.alma9_sshminion.configuration

  centos7_client_configuration    = module.centos7_client.configuration
  centos7_minion_configuration    = module.centos7_minion.configuration
  centos7_sshminion_configuration = module.centos7_sshminion.configuration

  liberty9_minion_configuration    = module.liberty9_minion.configuration
  liberty9_sshminion_configuration = module.liberty9_sshminion.configuration

  oracle9_minion_configuration    = module.oracle9_minion.configuration
  oracle9_sshminion_configuration = module.oracle9_sshminion.configuration

  // rhel9 is tested only in AWS for legal reasons

  rocky8_minion_configuration    = module.rocky8_minion.configuration
  rocky8_sshminion_configuration = module.rocky8_sshminion.configuration

  rocky9_minion_configuration    = module.rocky9_minion.configuration
  rocky9_sshminion_configuration = module.rocky9_sshminion.configuration

  ubuntu2004_minion_configuration    = module.ubuntu2004_minion.configuration
  ubuntu2004_sshminion_configuration = module.ubuntu2004_sshminion.configuration

  ubuntu2204_minion_configuration    = module.ubuntu2204_minion.configuration
  ubuntu2204_sshminion_configuration = module.ubuntu2204_sshminion.configuration

  ubuntu2404_minion_configuration    = module.ubuntu2404_minion.configuration
  ubuntu2404_sshminion_configuration = module.ubuntu2404_sshminion.configuration

  debian12_minion_configuration    = module.debian12_minion.configuration
  debian12_sshminion_configuration = module.debian12_sshminion.configuration

  opensuse156arm_minion_configuration    = module.opensuse156arm_minion.configuration
  opensuse156arm_sshminion_configuration = module.opensuse156arm_sshminion.configuration

  sle15sp5s390_minion_configuration    = module.sle15sp5s390_minion.configuration
  sle15sp5s390_sshminion_configuration = module.sle15sp5s390_sshminion.configuration

  salt_migration_minion_configuration = module.salt_migration_minion.configuration

  slemicro51_minion_configuration    = module.slemicro51_minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slemicro51_sshminion_configuration = module.slemicro51_sshminion.configuration

  slemicro52_minion_configuration    = module.slemicro52_minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slemicro52_sshminion_configuration = module.slemicro52_sshminion.configuration

  slemicro53_minion_configuration    = module.slemicro53_minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slemicro53_sshminion_configuration = module.slemicro53_sshminion.configuration

  slemicro54_minion_configuration    = module.slemicro54_minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slemicro54_sshminion_configuration = module.slemicro54_sshminion.configuration

  slemicro55_minion_configuration    = module.slemicro55_minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slemicro55_sshminion_configuration = module.slemicro55_sshminion.configuration

  slmicro60_minion_configuration    = module.slmicro60_minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slmicro60_sshminion_configuration = module.slmicro60_sshminion.configuration

  slmicro61_minion_configuration    = module.slmicro61_minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slmicro61_sshminion_configuration = module.slmicro61_sshminion.configuration

  sle12sp5_buildhost_configuration = module.sle12sp5_buildhost.configuration
  sle15sp4_buildhost_configuration = module.sle15sp4_buildhost.configuration

  sle12sp5_terminal_configuration = module.sle12sp5_terminal.configuration
  sle15sp4_terminal_configuration = module.sle15sp4_terminal.configuration

  monitoringserver_configuration = module.monitoring-server.configuration
}

output "configuration" {
  value = {
    controller  = module.controller.configuration
    server      = module.server.configuration
  }
}
