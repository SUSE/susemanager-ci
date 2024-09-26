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
  default = "https://github.com/SUSE/spacewalk.git"
}

variable "CUCUMBER_BRANCH" {
  type = string
  default = "Manager-5.0"
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
      version = "0.0.6"
    }
  }
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
  alias = "suma-arm"
  uri = "qemu+tcp://suma-arm.mgr.suse.de/system"
}

provider "feilong" {
  connector   = "https://10.144.68.9"
  admin_token = var.ZVM_ADMIN_TOKEN
  local_user  = "jenkins@jenkins-worker.mgr.prv.suse.net"
}

module "base_core" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles15sp4o", "opensuse155o", "slemicro55o" ]

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
    libvirt = libvirt.tatooine
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50-"
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
    libvirt = libvirt.tatooine
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "almalinux8o", "almalinux9o", "centos7o", "oraclelinux9o", "rocky8o", "rocky9o", "libertylinux9o" ]

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
    libvirt = libvirt.florina
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles15sp2o", "sles15sp3o", "sles15sp4o", "sles15sp5o", "sles15sp6o", "slemicro51-ign", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "slemicro55o", "slmicro60o"  ]

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
    libvirt = libvirt.terminus
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles12sp5o", "sles15sp3o", "sles15sp4o", "opensuse155o", "opensuse156o", "slemicro55o" ]

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
    libvirt = libvirt.trantor
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "ubuntu2004o", "ubuntu2204o", "debian11o", "debian12o" ]

  mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

module "base_arm" {
  providers = {
    libvirt = libvirt.suma-arm
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-50-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "opensuse155armo", "opensuse156armo" ]

  mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br0"
  }
}

module "base_s390" {
  source = "./backend_modules/feilong/base"

  name_prefix = "suma-bv-50-"
  domain      = "mgr.prv.suse.net"

  testsuite   = true
}

module "server_containerized" {
  source             = "./modules/server_containerized"
  base_configuration = module.base_core.configuration
  product_version    = "5.0-released"
  name               = "server"
  image              = "slemicro55o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:01"
    memory             = 40960
    vcpu               = 10
    data_pool          = "ssd"
  }
  main_disk_size = 3000
  runtime = "podman"
  container_repository = "registry.suse.de/suse/sle-15-sp6/update/products/manager50/containerfile"

  server_mounted_mirror          = "minima-mirror-ci-bv.mgr.prv.suse.net"
  java_debugging                 = false
  auto_accept                    = false
  disable_firewall               = false
  allow_postgres_connections     = false
  skip_changelog_import          = false
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

module "proxy_containerized" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/proxy_containerized"
  base_configuration = module.base_retail.configuration
  product_version    = "5.0-released"
  name               = "proxy"
  provider_settings = {
    mac                = "aa:b2:92:05:00:02"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-server.mgr.prv.suse.net"
    username = "admin"
    password = "admin"
  }
  runtime = "podman"
  container_repository = "registry.suse.de/suse/sle-15-sp6/update/products/manager50/containerfile"
  auto_configure            = false
  ssh_key_path              = "./salt/controller/id_rsa.pub"
}

module "sles12sp5_minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "head"
  name               = "sles12sp5-minion"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:11"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp2_minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "sles15sp2-minion"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:14"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp3_minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "sles15sp3-minion"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:15"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp4_minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "sles15sp4-minion"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:16"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp5_minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "sles15sp5-minion"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:12"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp6_minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "sles15sp6-minion"
  image              = "sles15sp6o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:10"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "alma8_minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "alma8-minion"
  image              = "almalinux8o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:19"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "alma9_minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "alma9-minion"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:22"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "centos7_minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "centos7-minion"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:17"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "liberty9_minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "liberty9-minion"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:25"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "oracle9_minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "oracle9-minion"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:23"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky8_minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "rocky8-minion"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:18"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky9_minion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "rocky9-minion"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:21"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2004_minion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "5.0-released"
  name               = "ubuntu2004-minion"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:1a"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  # WORKAROUND https://github.com/uyuni-project/uyuni/issues/7637
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2204_minion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "5.0-released"
  name               = "ubuntu2204-minion"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:1b"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "debian11_minion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "5.0-released"
  name               = "debian11-minion"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:1e"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "debian12_minion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "5.0-released"
  name               = "debian12-minion"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:1c"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "opensuse155arm_minion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  product_version    = "5.0-released"
  name               = "opensuse155arm-minion-prv"
  image              = "opensuse155armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:08"
    overwrite_fqdn     = "suma-bv-50-opensuse155arm-minion.mgr.prv.suse.net"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "opensuse156arm_minion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  product_version    = "5.0-released"
  name               = "opensuse156arm-minion-prv"
  image              = "opensuse156armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:0a"
    overwrite_fqdn     = "suma-bv-50-opensuse156arm-minion.mgr.prv.suse.net"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp5s390_minion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration
  product_version    = "5.0-released"

  name               = "sles15sp5s390-minion"
  image              = "s15s5-minimal-2part-xfs"

  provider_settings = {
    userid             = "S50MIPRV"
    mac                = "02:3a:fc:02:01:32"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

// This is an x86_64 SLES 15 SP5 minion (like sles15sp5-minion),
// dedicated to testing migration from OS Salt to Salt bundle
module "salt_migration_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "salt-migration-minion"
  product_version    = "5.0-released"
  image              = "sles15sp5o"
  provider_settings  = {
    mac                = "aa:b2:92:05:00:2f"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = true
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  install_salt_bundle = false
}

module "slemicro51_minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "slemicro51-minion"
  image              = "slemicro51-ign"
  provider_settings = {
    mac                = "aa:b2:92:05:00:26"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
}

module "slemicro52_minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "slemicro52-minion"
  image              = "slemicro52-ign"
  provider_settings = {
    mac                = "aa:b2:92:05:00:27"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
}

module "slemicro53_minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "slemicro53-minion"
  image              = "slemicro53-ign"
  provider_settings = {
    mac                = "aa:b2:92:05:00:28"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
}

module "slemicro54_minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "slemicro54-minion"
  image              = "slemicro54-ign"
  provider_settings = {
    mac                = "aa:b2:92:05:00:29"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
}

module "slemicro55_minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "slemicro55-minion"
  image              = "slemicro55o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:2a"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
}

module "slmicro60_minion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "slmicro60-minion"
  image              = "slmicro60o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:2b"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
  install_salt_bundle = false
}

module "sles12sp5_sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "5.0-released"
  name               = "sles12sp5-sshminion"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:31"
    memory             = 4096
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp2_sshminion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "sles15sp2-sshminion"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:34"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp3_sshminion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "sles15sp3-sshminion"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:35"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp4_sshminion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "sles15sp4-sshminion"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:36"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp5_sshminion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "sles15sp5-sshminion"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:32"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp6_sshminion" {
  providers = {
    libvirt = libvirt.florina
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "5.0-released"
  name               = "sles15sp6-sshminion"
  image              = "sles15sp6o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:30"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "alma8_sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "alma8-sshminion"
  image              = "almalinux8o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:39"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "alma9_sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "alma9-sshminion"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:42"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "centos7_sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "centos7-sshminion"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:37"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "liberty9_sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "liberty9-sshminion"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:45"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "oracle9_sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "oracle9-sshminion"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:43"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky8_sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "rocky8-sshminion"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:38"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "rocky9_sshminion" {
  providers = {
    libvirt = libvirt.tatooine
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "5.0-released"
  name               = "rocky9-sshminion"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:41"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2004_sshminion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "5.0-released"
  name               = "ubuntu2004-sshminion"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:3a"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  # WORKAROUND https://github.com/uyuni-project/uyuni/issues/7637
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2204_sshminion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "5.0-released"
  name               = "ubuntu2204-sshminion"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:3b"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "debian11_sshminion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "5.0-released"
  name               = "debian11-sshminion"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:3e"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "debian12_sshminion" {
  providers = {
    libvirt = libvirt.trantor
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "5.0-released"
  name               = "debian12-sshminion"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:3c"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "opensuse155arm_sshminion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_arm.configuration
  product_version    = "5.0-released"
  name               = "opensuse155arm-sshminion-prv"
  image              = "opensuse155armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:09"
    overwrite_fqdn     = "suma-bv-50-opensuse155arm-sshminion.mgr.prv.suse.net"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "opensuse156arm_sshminion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_arm.configuration
  product_version    = "5.0-released"
  name               = "opensuse156arm-sshminion-prv"
  image              = "opensuse156armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:0b"
    overwrite_fqdn     = "suma-bv-50-opensuse156arm-sshminion.mgr.prv.suse.net"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp5s390_sshminion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration
  product_version    = "5.0-released"

  name               = "sles15sp5s390-sshminion"
  image              = "s15s5-minimal-2part-xfs"

  provider_settings = {
    userid             = "S50SSPRV"
    mac                = "02:3a:fc:02:01:33"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro51_sshminion" {
//   providers = {
//     libvirt = libvirt.florina
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   product_version    = "5.0-released"
//   name               = "slemicro51-sshminion"
//   image              = "slemicro51-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:46"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro52_sshminion" {
//   providers = {
//     libvirt = libvirt.florina
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   product_version    = "5.0-released"
//   name               = "slemicro52-sshminion"
//   image              = "slemicro52-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:47"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro53_sshminion" {
//   providers = {
//     libvirt = libvirt.florina
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   product_version    = "5.0-released"
//   name               = "slemicro53-sshminion"
//   image              = "slemicro53-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:48"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro54_sshminion" {
//   providers = {
//     libvirt = libvirt.florina
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   product_version    = "5.0-released"
//   name               = "slemicro54-sshminion"
//   image              = "slemicro54-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:49"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro55_sshminion" {
//   providers = {
//     libvirt = libvirt.florina
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   product_version    = "5.0-released"
//   name               = "slemicro55-sshminion"
//   image              = "slemicro55o"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:4a"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slmicro60_sshminion" {
//   providers = {
//     libvirt = libvirt.florina
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   product_version    = "5.0-released"
//   name               = "slmicro60-sshminion"
//   image              = "slmicro60o"
//   provider_settings = {
//     mac                = "aa:b2:92:05:00:4b"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
// }

module "sles12sp5_buildhost" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/build_host"
  base_configuration = module.base_retail.configuration
  product_version    = "5.0-released"
  name               = "sles12sp5-build"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:04"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles12sp5_terminal" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/pxe_boot"
  base_configuration = module.base_retail.configuration
  name               = "sles12sp5-terminional"
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

module "sles15sp4_buildhost" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/build_host"
  base_configuration = module.base_retail.configuration
  product_version    = "5.0-released"
  name               = "sles15sp4-build"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:05"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp4_terminal" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/pxe_boot"
  base_configuration = module.base_retail.configuration
  name               = "sles15sp4-terminional"
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

module "dhcp_dns" {
  source             = "./modules/dhcp_dns"
  base_configuration = module.base_retail.configuration
  name               = "dns-dhcp"
  image              = "opensuse155o"
  private_hosts = [
    module.proxy_containerized.configuration,
    module.sles12sp5_terminal.configuration,
    module.sles15sp4_terminal.configuration
  ]
  hypervisor = {
    host        = "terminus.mgr.prv.suse.net"
    user        = "root"
    private_key = file("~/.ssh/id_rsa")
  }
}

module "monitoring_server" {
  providers = {
    libvirt = libvirt.terminus
  }
  source             = "./modules/minion"
  base_configuration = module.base_retail.configuration
  product_version    = "5.0-released"
  name               = "monitoring"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:05:00:03"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-proxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base_core.configuration
  name               = "controller"
  provider_settings = {
    mac                = "aa:b2:92:05:00:00"
    memory             = 16384
    vcpu               = 8
  }
  swap_file_size = null
  product_version    = "5.0-released"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration = module.server_containerized.configuration

  proxy_configuration  = module.proxy_containerized.configuration

  sle12sp5_minion_configuration    = module.sles12sp5_minion.configuration
  sle12sp5_sshminion_configuration = module.sles12sp5_sshminion.configuration

  sle15sp2_minion_configuration    = module.sles15sp2_minion.configuration
  sle15sp2_sshminion_configuration = module.sles15sp2_sshminion.configuration

  sle15sp3_minion_configuration    = module.sles15sp3_minion.configuration
  sle15sp3_sshminion_configuration = module.sles15sp3_sshminion.configuration

  sle15sp4_minion_configuration    = module.sles15sp4_minion.configuration
  sle15sp4_sshminion_configuration = module.sles15sp4_sshminion.configuration

  sle15sp5_minion_configuration    = module.sles15sp5_minion.configuration
  sle15sp5_sshminion_configuration = module.sles15sp5_sshminion.configuration

  sle15sp6_minion_configuration    = module.sles15sp6_minion.configuration
  sle15sp6_sshminion_configuration = module.sles15sp6_sshminion.configuration

  alma8_minion_configuration    = module.alma8_minion.configuration
  alma8_sshminion_configuration = module.alma8_sshminion.configuration

  alma9_minion_configuration    = module.alma9_minion.configuration
  alma9_sshminion_configuration = module.alma9_sshminion.configuration

  centos7_minion_configuration    = module.centos7_minion.configuration
  centos7_sshminion_configuration = module.centos7_sshminion.configuration

  liberty9_minion_configuration    = module.liberty9_minion.configuration
  liberty9_sshminion_configuration = module.liberty9_sshminion.configuration

  oracle9_minion_configuration    = module.oracle9_minion.configuration
  oracle9_sshminion_configuration = module.oracle9_sshminion.configuration

  rocky8_minion_configuration    = module.rocky8_minion.configuration
  rocky8_sshminion_configuration = module.rocky8_sshminion.configuration

  rocky9_minion_configuration    = module.rocky9_minion.configuration
  rocky9_sshminion_configuration = module.rocky9_sshminion.configuration

  ubuntu2004_minion_configuration    = module.ubuntu2004_minion.configuration
  ubuntu2004_sshminion_configuration = module.ubuntu2004_sshminion.configuration

  ubuntu2204_minion_configuration    = module.ubuntu2204_minion.configuration
  ubuntu2204_sshminion_configuration = module.ubuntu2204_sshminion.configuration

  debian11_minion_configuration    = module.debian11_minion.configuration
  debian11_sshminion_configuration = module.debian11_sshminion.configuration

  debian12_minion_configuration    = module.debian12_minion.configuration
  debian12_sshminion_configuration = module.debian12_sshminion.configuration

  opensuse155arm_minion_configuration    = module.opensuse155arm_minion.configuration
  opensuse155arm_sshminion_configuration = module.opensuse155arm_sshminion.configuration

  opensuse156arm_minion_configuration    = module.opensuse156arm_minion.configuration
  opensuse156arm_sshminion_configuration = module.opensuse156arm_sshminion.configuration

  sle15sp5s390_minion_configuration    = module.sles15sp5s390_minion.configuration
  sle15sp5s390_sshminion_configuration = module.sles15sp5s390_sshminion.configuration

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

  sle12sp5_buildhost_configuration = module.sles12sp5_buildhost.configuration
  sle15sp4_buildhost_configuration = module.sles15sp4_buildhost.configuration

  sle12sp5_terminal_configuration = module.sles12sp5_terminal.configuration
  sle15sp4_terminal_configuration = module.sles15sp4_terminal.configuration

  monitoringserver_configuration = module.monitoring_server.configuration
}

output "configuration" {
  value = {
    controller = module.controller.configuration
  }
}
