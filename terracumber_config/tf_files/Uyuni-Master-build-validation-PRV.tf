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
  uri = "qemu+tcp://giediprime.mgr.prv.suse.net/system"
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
  alias = "margarita"
  uri = "qemu+tcp://margarita.mgr.prv.suse.net/system"
}

provider "libvirt" {
  alias = "caipirinha"
  uri = "qemu+tcp://caipirinha.mgr.prv.suse.net/system"
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
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles15sp4o", "opensuse155o", "opensuse156o" ]

  mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
    additional_network = "192.168.100.0/24"
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
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "almalinux8o", "almalinux9o", "centos7o", "oraclelinux9o", "rocky8o", "rocky9o" ]

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
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles15sp1o", "sles15sp2o", "sles15sp3o", "sles15sp4o", "sles15sp5o", "sles15sp6o", "slemicro51-ign", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "slemicro55o", "slmicro60o" ]

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
    libvirt = libvirt.margarita
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "sles12sp5o", "sles15sp3o", "sles15sp4o", "opensuse155o" ]

  mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
    additional_network = "192.168.100.0/24"
  }
}

module "base_debian" {
  providers = {
    libvirt = libvirt.caipirinha
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "ubuntu2004o", "ubuntu2204o", "debian10o", "debian11o", "debian12o" ]

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
  name_prefix = "uyuni-bv-master-"
  use_avahi   = false
  domain      = "mgr.prv.suse.net"
  images      = [ "opensuse154armo", "opensuse155armo", "opensuse156armo" ]

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

  name_prefix = "uyuni-bv-master-"
  domain      = "mgr.prv.suse.net"

  testsuite   = true
}

module "server_containerized" {
  source             = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "srv"
  provider_settings = {
    mac                = "aa:b2:93:04:05:6d"
    memory             = 40960
    vcpu               = 10
    data_pool          = "ssd"
  }

  server_mounted_mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
  main_disk_size        = 20
  repository_disk_size  = 2048
  database_disk_size    = 150

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
  ssh_key_path                   = "./salt/controller/id_rsa.pub"
  from_email                     = "root@suse.de"
  accept_all_ssl_protocols       = true

  runtime = "podman"
  container_repository = "registry.opensuse.org/systemsmanagement/uyuni/master/containers/uyuni"
  container_tag = "latest"
  helm_chart_url = "oci://registry.opensuse.org/systemsmanagement/uyuni/master/charts/uyuni/server"
  login_timeout = 28800

  //server_additional_repos

}

module "proxy_containerized" {
  providers = {
    libvirt = libvirt.margarita
  }
  source             = "./modules/proxy"
  base_configuration = module.base_retail.configuration
  product_version    = "uyuni-master"
  name               = "pxy"
  provider_settings = {
    mac                = "aa:b2:93:04:05:6e"
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

  runtime = "podman"
  container_repository = "registry.opensuse.org/systemsmanagement/uyuni/master/containers/uyuni"
  container_tag = "latest"
}

// No traditional clients in Uyuni

module "sles12sp5-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_old_sle.configuration
  product_version    = "uyuni-master"
  name               = "min-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:7d"
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
  product_version    = "uyuni-master"
  name               = "min-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:7f"
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
  product_version    = "uyuni-master"
  name               = "min-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:80"
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
  product_version    = "uyuni-master"
  name               = "min-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:81"
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
  product_version    = "uyuni-master"
  name               = "min-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:82"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-master"
  name               = "min-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:7e"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp6-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "uyuni-master"
  name               = "min-sles15sp6"
  image              = "sles15sp6o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:7c"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "alma8-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-master"
  name               = "min-alma8"
  image              = "almalinux8o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:85"
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

module "alma9-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-master"
  name               = "min-alma9"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:8e"
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

module "centos7-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-master"
  name               = "min-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:83"
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


module "oracle9-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-master"
  name               = "min-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:8f"
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

module "rocky8-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-master"
  name               = "min-rocky8"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:84"
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

module "rocky9-minion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/minion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-master"
  name               = "min-rocky9"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:8d"
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

module "ubuntu2004-minion" {
  providers = {
    libvirt = libvirt.caipirinha
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-master"
  name               = "min-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:86"
    memory             = 4096
  }
  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
    libvirt = libvirt.caipirinha
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-master"
  name               = "min-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:87"
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
    libvirt = libvirt.caipirinha
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-master"
  name               = "min-debian10"
  image              = "debian10o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:89"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  # WORKAROUND https://github.com/uyuni-project/uyuni/issues/7637
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "debian11-minion" {
  providers = {
    libvirt = libvirt.caipirinha
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-master"
  name               = "min-debian11"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:8a"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian12-minion" {
  providers = {
    libvirt = libvirt.caipirinha
  }
  source             = "./modules/minion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-master"
  name               = "min-debian12"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:88"
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

module "opensuse154arm-minion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  product_version    = "uyuni-master"
  name               = "prv-min-opensuse154arm"
  image              = "opensuse154armo"
  provider_settings = {
    mac                = "aa:b2:93:02:01:f8"
    overwrite_fqdn     = "uyuni-bv-master-min-opensuse154arm.mgr.prv.suse.net"
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

module "opensuse155arm-minion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  product_version    = "uyuni-master"
  name               = "prv-min-opensuse155arm"
  image              = "opensuse155armo"
  provider_settings = {
    mac                = "aa:b2:93:02:01:f9"
    overwrite_fqdn     = "uyuni-bv-master-min-opensuse155arm.mgr.prv.suse.net"
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

module "opensuse156arm-minion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  product_version    = "uyuni-master"
  name               = "prv-min-opensuse156arm"
  image              = "opensuse156armo"
  provider_settings = {
    mac                = "aa:b2:92:05:00:10"
    overwrite_fqdn     = "uyuni-bv-master-min-opensuse156arm.mgr.prv.suse.net"
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

module "sles15sp5s390-minion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration

  name               = "min-sles15sp5s390"
  image              = "s15s5-minimal-2part-xfs"

  provider_settings = {
    userid             = "UYMMIPRV"
    mac                = "02:3a:fc:02:01:34"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "salt-migration-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  name               = "min-salt-migration"
  product_version    = "uyuni-master"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:9b"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = true
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}


module "slemicro51-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "uyuni-master"
  name               = "min-slemicro51"
  image              = "slemicro51-ign"
  provider_settings = {
    mac                = "aa:b2:93:04:05:92"
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
  product_version    = "uyuni-master"
  name               = "min-slemicro52"
  image              = "slemicro52-ign"
  provider_settings = {
    mac                = "aa:b2:93:04:05:93"
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
  product_version    = "uyuni-master"
  name               = "min-slemicro53"
  image              = "slemicro53-ign"
  provider_settings = {
    mac                = "aa:b2:93:04:05:94"
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
  product_version    = "uyuni-master"
  name               = "min-slemicro54"
  image              = "slemicro54-ign"
  provider_settings = {
    mac                = "aa:b2:93:04:05:95"
    memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-master"
  name               = "min-slemicro55"
  image              = "slemicro55o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:96"
    memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slmicro60-minion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/minion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "uyuni-master"
  name               = "min-slmicro60"
  image              = "slmicro60o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:97"
    memory             = 2048
  }

  server_configuration = {
    hostname = "uyuni-bv-master-pxy.mgr.prv.suse.net"
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
  product_version    = "uyuni-master"
  name               = "minssh-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:9d"
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
  product_version    = "uyuni-master"
  name               = "minssh-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:9f"
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
  product_version    = "uyuni-master"
  name               = "minssh-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:a0"
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
  product_version    = "uyuni-master"
  name               = "minssh-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:a1"
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
  product_version    = "uyuni-master"
  name               = "minssh-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:a2"
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
  product_version    = "uyuni-master"
  name               = "minssh-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:9e"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp6-sshminion" {
  providers = {
    libvirt = libvirt.ginfizz
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_new_sle.configuration
  product_version    = "uyuni-master"
  name               = "minssh-sles15sp6"
  image              = "sles15sp6o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:9c"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "alma8-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-master"
  name               = "minssh-alma8"
  image              = "almalinux8o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:a5"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "alma9-sshminion" {
  providers = {
    libvirt = libvirt.cosmopolitan
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_res.configuration
  product_version    = "uyuni-master"
  name               = "minssh-alma9"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:ae"
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
  product_version    = "uyuni-master"
  name               = "minssh-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:a3"
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
  product_version    = "uyuni-master"
  name               = "minssh-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:af"
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
  product_version    = "uyuni-master"
  name               = "minssh-rocky8"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:a4"
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
  product_version    = "uyuni-master"
  name               = "minssh-rocky9"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:ad"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2004-sshminion" {
  providers = {
    libvirt = libvirt.caipirinha
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-master"
  name               = "minssh-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:a6"
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
    libvirt = libvirt.caipirinha
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-master"
  name               = "minssh-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:a7"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

// Debian 9 is not supported by 4.3

module "debian10-sshminion" {
  providers = {
    libvirt = libvirt.caipirinha
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-master"
  name               = "minssh-debian10"
  image              = "debian10o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:a9"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  # WORKAROUND https://github.com/uyuni-project/uyuni/issues/7637
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "debian11-sshminion" {
  providers = {
    libvirt = libvirt.caipirinha
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-master"
  name               = "minssh-debian11"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:aa"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian12-sshminion" {
  providers = {
    libvirt = libvirt.caipirinha
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_debian.configuration
  product_version    = "uyuni-master"
  name               = "minssh-debian12"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:a8"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "opensuse154arm-sshminion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_arm.configuration
  product_version    = "uyuni-master"
  name               = "prv-minssh-opensuse154arm"
  image              = "opensuse154armo"
  provider_settings = {
    mac                = "aa:b2:93:02:01:fa"
    overwrite_fqdn     = "uyuni-bv-master-minssh-opensuse154arm.mgr.prv.suse.net"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "opensuse155arm-sshminion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_arm.configuration
  product_version    = "uyuni-master"
  name               = "prv-minssh-opensuse155arm"
  image              = "opensuse155armo"
  provider_settings = {
    mac                = "aa:b2:93:02:01:fb"
    overwrite_fqdn     = "uyuni-bv-master-minssh-opensuse155arm.mgr.prv.suse.net"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "opensuse156arm-sshminion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_arm.configuration
  product_version    = "uyuni-master"
  name               = "prv-minssh-opensuse156arm"
  image              = "opensuse156armo"
  provider_settings = {
    mac                = "aa:b2:92:05:00:11"
    overwrite_fqdn     = "uyuni-bv-master-minssh-opensuse156arm.mgr.prv.suse.net"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp5s390-sshminion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration

  name               = "minssh-sles15sp5s390"
  image              = "s15s5-minimal-2part-xfs"

  provider_settings = {
    userid             = "UYMSSPRV"
    mac                = "02:3a:fc:02:01:35"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro51-sshminion" {
//   providers = {
//     libvirt = libvirt.ginfizz
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   product_version    = "uyuni-master"
//   name               = "minssh-slemicro51"
//   image              = "slemicro51-ign"
//   provider_settings = {
//     mac                = "aa:b2:93:04:05:b2"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro52-sshminion" {
//   providers = {
//     libvirt = libvirt.ginfizz
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   product_version    = "uyuni-master"
//   name               = "minssh-slemicro52"
//   image              = "slemicro52-ign"
//   provider_settings = {
//     mac                = "aa:b2:93:04:05:b3"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro53-sshminion" {
//   providers = {
//     libvirt = libvirt.ginfizz
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   product_version    = "uyuni-master"
//   name               = "minssh-slemicro53"
//   image              = "slemicro53-ign"
//   provider_settings = {
//     mac                = "aa:b2:93:04:05:b4"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro54-sshminion" {
//   providers = {
//     libvirt = libvirt.ginfizz
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   product_version    = "uyuni-master"
//   name               = "minssh-slemicro54"
//   image              = "slemicro54-ign"
//   provider_settings = {
//     mac                = "aa:b2:93:04:05:b5"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro55-sshminion" {
//   providers = {
//     libvirt = libvirt.ginfizz
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   product_version    = "uyuni-master"
//   name               = "minssh-slemicro55"
//   image              = "slemicro55o"
//   provider_settings = {
//     mac                = "aa:b2:93:04:05:b6"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slmicro60-sshminion" {
//   providers = {
//     libvirt = libvirt.ginfizz
//   }
//   source             = "./modules/sshminion"
//   base_configuration = module.base_new_sle.configuration
//   product_version    = "uyuni-master"
//   name               = "minssh-slmicro60"
//   image              = "slmicro60o"
//   provider_settings = {
//     mac                = "aa:b2:93:02:01:b7"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

module "sles12sp5-buildhost" {
  providers = {
    libvirt = libvirt.margarita
  }
  source             = "./modules/build_host"
  base_configuration = module.base_retail.configuration
  product_version    = "uyuni-master"
  name               = "build-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:70"
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
    libvirt = libvirt.margarita
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
  private_ip         = 5
  private_name       = "sle12sp5terminal"
}

module "sles15sp4-buildhost" {
  providers = {
    libvirt = libvirt.margarita
  }
  source             = "./modules/build_host"
  base_configuration = module.base_retail.configuration
  product_version    = "uyuni-master"
  name               = "build-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:71"
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
    libvirt = libvirt.margarita
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
  private_ip         = 6
  private_name       = "sle15sp4terminal"
}

module "monitoring-server" {
  providers = {
    libvirt = libvirt.margarita
  }
  source             = "./modules/minion"
  base_configuration = module.base_retail.configuration
  product_version    = "uyuni-master"
  name               = "monitoring"
  image              = "opensuse155o"
  provider_settings = {
    mac                = "aa:b2:93:04:05:6f"
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
    mac                = "aa:b2:93:04:05:6c"
    memory             = 16384
    vcpu               = 8
  }
  swap_file_size = null
  catch_timeout_message = true

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration = module.server.configuration
  proxy_configuration  = module.proxy.configuration

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

  sle15sp6_minion_configuration    = module.sles15sp6-minion.configuration
  sle15sp6_sshminion_configuration = module.sles15sp6-sshminion.configuration

  alma8_minion_configuration    = module.alma8-minion.configuration
  alma8_sshminion_configuration = module.alma8-sshminion.configuration

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

  debian12_minion_configuration    = module.debian12-minion.configuration
  debian12_sshminion_configuration = module.debian12-sshminion.configuration

  opensuse154arm_minion_configuration    = module.opensuse154arm-minion.configuration
  opensuse154arm_sshminion_configuration = module.opensuse154arm-sshminion.configuration

  opensuse155arm_minion_configuration    = module.opensuse155arm-minion.configuration
  opensuse155arm_sshminion_configuration = module.opensuse155arm-sshminion.configuration

  opensuse156arm_minion_configuration    = module.opensuse156arm-minion.configuration
  opensuse156arm_sshminion_configuration = module.opensuse156arm-sshminion.configuration

  sle15sp5s390_minion_configuration    = module.sles15sp5s390-minion.configuration
  sle15sp5s390_sshminion_configuration = module.sles15sp5s390-sshminion.configuration

  salt_migration_minion_configuration = module.salt-migration-minion.configuration

  slemicro51_minion_configuration    = module.slemicro51-minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slemicro51_sshminion_configuration = module.slemicro51-sshminion.configuration

  slemicro52_minion_configuration    = module.slemicro52-minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slemicro52_sshminion_configuration = module.slemicro52-sshminion.configuration

  slemicro53_minion_configuration    = module.slemicro53-minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slemicro53_sshminion_configuration = module.slemicro53-sshminion.configuration

  slemicro54_minion_configuration    = module.slemicro54-minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slemicro54_sshminion_configuration = module.slemicro54-sshminion.configuration

  slemicro55_minion_configuration    = module.slemicro55-minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slemicro55_sshminion_configuration = module.slemicro55-sshminion.configuration

  slmicro60_minion_configuration    = module.slmicro60-minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slmicro60_sshminion_configuration = module.slmicro60-sshminion.configuration

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
