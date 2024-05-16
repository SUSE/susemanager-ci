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
      version = "0.6.3"
    }
    feilong = {
      source = "bischoff/feilong"
      version = "0.0.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://suma-07.mgr.suse.de/system"
}

provider "libvirt" {
  alias = "suma-arm"
  uri = "qemu+tcp://suma-arm.mgr.suse.de/system"
}

provider "feilong" {
  connector   = "https://10.144.68.9"
  admin_token = var.ZVM_ADMIN_TOKEN
  local_user  = "jenkins@jenkins-worker.mgr.suse.de"
}

module "base_core" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-43-"
  use_avahi   = false
  domain      = "mgr.suse.de"
  images      = [ "sles12sp5o", "sles15sp1o", "sles15sp2o", "sles15sp3o", "sles15sp4o", "sles15sp5o", "sles15sp6o", "slemicro51-ign", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "slemicro55o", "slemicro60o", "almalinux8o", "almalinux9o", "centos7o", "libertylinux9o", "oraclelinux9o", "rocky8o", "rocky9o", "ubuntu2004o", "ubuntu2204o", "debian11o", "debian12o", "opensuse155o", "opensuse156o" ]

  mirror = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br0"
    additional_network = "192.168.43.0/24"
  }
}

module "base_arm" {
  providers = {
    libvirt = libvirt.suma-arm
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "suma-bv-43-"
  use_avahi   = false
  domain      = "mgr.suse.de"
  images      = [ "opensuse154armo", "opensuse155armo", "opensuse156armo" ]

  mirror = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images = true

  testsuite = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br0"
  }
}

module "base_s390" {
  source = "./backend_modules/feilong/base"

  name_prefix = "suma-bv-43-"
  domain      = "mgr.suse.de"

  testsuite   = true
}

module "server" {
  source             = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "srv"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a1"
    memory             = 40960
    vcpu               = 10
    data_pool          = "ssd"
  }

  server_mounted_mirror          = "minima-mirror-ci-bv.mgr.suse.de"
  main_disk_size                 = 20
  repository_disk_size           = 2048
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
  ssh_key_path                   = "./salt/controller/id_rsa.pub"
  from_email                     = "root@suse.de"
  accept_all_ssl_protocols       = true

  //server_additional_repos

}

module "proxy" {
  source             = "./modules/proxy"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "pxy"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a2"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-srv.mgr.suse.de"
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

module "sles12sp5-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "cli-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a9"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp1-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "cli-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:ab"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp2-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "cli-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:ac"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp3-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "cli-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:ad"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "cli-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:ae"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp5-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "cli-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:aa"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp6-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "cli-sles15sp6"
  image              = "sles15sp6o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a8"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "centos7-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "cli-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:af"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles12sp5-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b1"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp1-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b3"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp2-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b4"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp3-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b5"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b6"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp5-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b2"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp6-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp6"
  image              = "sles15sp6o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b0"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "alma8-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-alma8"
  image              = "almalinux8o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b9"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "alma9-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-alma9"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:c2"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
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
  product_version    = "4.3-released"
  name               = "min-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b7"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "liberty9-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-liberty9"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:c5"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
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
  product_version    = "4.3-released"
  name               = "min-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:c3"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
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
  product_version    = "4.3-released"
  name               = "min-rocky8"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:b8"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
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
  product_version    = "4.3-released"
  name               = "min-rocky9"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:c1"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
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
  product_version    = "4.3-released"
  name               = "min-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:ba"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  # WORKAROUND https://github.com/uyuni-project/uyuni/issues/7637
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2204-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:bb"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

// Debian 9 and 10 are not supported by 4.3

module "debian11-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-debian11"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:be"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian12-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-debian12"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:bc"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
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
  product_version    = "4.3-released"
  name               = "nue-min-opensuse154arm"
  image              = "opensuse154armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:bf"
    overwrite_fqdn     = "suma-bv-43-min-opensuse154arm.mgr.suse.de"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
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
  product_version    = "4.3-released"
  name               = "nue-min-opensuse155arm"
  image              = "opensuse155armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:c0"
    overwrite_fqdn     = "suma-bv-43-min-opensuse155arm.mgr.suse.de"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
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
  product_version    = "4.3-released"
  name               = "nue-min-opensuse156arm"
  image              = "opensuse156armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:ce"
    overwrite_fqdn     = "suma-bv-43-min-opensuse156arm.mgr.suse.de"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
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
    userid             = "S43MINUE"
    mac                = "02:3a:fc:42:00:28"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "salt-migration-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "min-salt-migration"
  product_version    = "4.3-released"
  image              = "sles15sp5o"
  provider_settings  = {
    mac                = "aa:b2:92:42:00:cf"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = true
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "slemicro51-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-slemicro51"
  image              = "slemicro51-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:c6"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  // WORKAROUND: Does not work in sumaform, yet
  //  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro52-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-slemicro52"
  image              = "slemicro52-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:c7"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  // WORKAROUND: Does not work in sumaform, yet
  //  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro53-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-slemicro53"
  image              = "slemicro53-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:c8"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  // WORKAROUND: Does not work in sumaform, yet
  //  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro54-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-slemicro54"
  image              = "slemicro54-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:c9"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  // WORKAROUND: Does not work in sumaform, yet
  //  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro55-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-slemicro55"
  image              = "slemicro55o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:ca"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  // WORKAROUND: Does not work in sumaform, yet
  //  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro60-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "min-slemicro60"
  image              = "slemicro60o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:cb"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp5-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:d1"
    memory             = 4096
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]
}

module "sles15sp1-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:d3"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

}

module "sles15sp2-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:d4"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp3-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:d5"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:d6"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp5-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:d2"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp6-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp6"
  image              = "sles15sp6o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:d0"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "alma8-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-alma8"
  image              = "almalinux8o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:d9"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "alma9-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-alma9"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:e2"
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
  product_version    = "4.3-released"
  name               = "minssh-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:d7"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "liberty9-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-liberty9"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:e5"
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
  product_version    = "4.3-released"
  name               = "minssh-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:e3"
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
  product_version    = "4.3-released"
  name               = "minssh-rocky8"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:d8"
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
  product_version    = "4.3-released"
  name               = "minssh-rocky9"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:e1"
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
  product_version    = "4.3-released"
  name               = "minssh-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:da"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  # WORKAROUND https://github.com/uyuni-project/uyuni/issues/7637
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "ubuntu2204-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:db"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

// Debian 9 and 10 are not supported by 4.3

module "debian11-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-debian11"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:de"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian12-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "minssh-debian12"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:dc"
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
  product_version    = "4.3-released"
  name               = "nue-minssh-opensuse154arm"
  image              = "opensuse154armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:df"
    overwrite_fqdn     = "suma-bv-43-minssh-opensuse154arm.mgr.suse.de"
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
  product_version    = "4.3-released"
  name               = "nue-minssh-opensuse155arm"
  image              = "opensuse155armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:e0"
    overwrite_fqdn     = "suma-bv-43-minssh-opensuse155arm.mgr.suse.de"
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
  product_version    = "4.3-released"
  name               = "nue-minssh-opensuse156arm"
  image              = "opensuse156armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:ee"
    overwrite_fqdn     = "suma-bv-43-minssh-opensuse156arm.mgr.suse.de"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

// Disable until sles15sp5s390-sshminion is correctly cleaned from feilong
// module "sles15sp5s390-sshminion" {
//  source             = "./backend_modules/feilong/host"
//  base_configuration = module.base_s390.configuration

//  name               = "minssh-sles15sp5s390"
//  image              = "s15s5-minimal-2part-xfs"

//  provider_settings = {
//    userid             = "S43SSNUE"
//    mac                = "02:3a:fc:42:00:29"
//    ssh_user           = "sles"
//    vswitch            = "VSUMA"
//  }

//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//}

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro51-sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   product_version    = "4.3-released"
//   name               = "minssh-slemicro51"
//   image              = "slemicro51-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:42:00:e6"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro52-sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   product_version    = "4.3-released"
//   name               = "minssh-slemicro52"
//   image              = "slemicro52-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:42:00:e7"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro53-sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   product_version    = "4.3-released"
//   name               = "minssh-slemicro53"
//   image              = "slemicro53-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:42:00:e8"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro54-sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   product_version    = "4.3-released"
//   name               = "minssh-slemicro54"
//   image              = "slemicro54-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:42:00:e9"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro55-sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   product_version    = "4.3-released"
//   name               = "minssh-slemicro55"
//   image              = "slemicro55o"
//   provider_settings = {
//     mac                = "aa:b2:92:42:00:ea"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro60-sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   product_version    = "4.3-released"
//   name               = "minssh-slemicro60"
//   image              = "slemicro60o"
//   provider_settings = {
//     mac                = "aa:b2:92:42:00:eb"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

module "sles12sp5-buildhost" {
  source             = "./modules/build_host"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "build-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a4"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
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
  private_ip         = 5
  private_name       = "sle12sp5terminal"
}

module "sles15sp4-buildhost" {
  source             = "./modules/build_host"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "build-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a5"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
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
  private_ip         = 6
  private_name       = "sle15sp4terminal"
}

module "monitoring-server" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "4.3-released"
  name               = "monitoring"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:a3"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-43-pxy.mgr.suse.de"
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
    mac                = "aa:b2:92:42:00:a0"
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

  sle15sp5_client_configuration    = module.sles15sp5-client.configuration
  sle15sp5_minion_configuration    = module.sles15sp5-minion.configuration
  sle15sp5_sshminion_configuration = module.sles15sp5-sshminion.configuration

  sle15sp6_client_configuration    = module.sles15sp6-client.configuration
  sle15sp6_minion_configuration    = module.sles15sp6-minion.configuration
  sle15sp6_sshminion_configuration = module.sles15sp6-sshminion.configuration

  alma8_minion_configuration    = module.alma8-minion.configuration
  alma8_sshminion_configuration = module.alma8-sshminion.configuration

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

  ubuntu2004_minion_configuration    = module.ubuntu2004-minion.configuration
  ubuntu2004_sshminion_configuration = module.ubuntu2004-sshminion.configuration

  ubuntu2204_minion_configuration    = module.ubuntu2204-minion.configuration
  ubuntu2204_sshminion_configuration = module.ubuntu2204-sshminion.configuration

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
// Disable until  sle15sp5s390_sshminion correctly clean from feilong
//  sle15sp5s390_sshminion_configuration = module.sles15sp5s390-sshminion.configuration

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

  slemicro60_minion_configuration    = module.slemicro60-minion.configuration
//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
//  slemicro60_sshminion_configuration = module.slemicro60-sshminion.configuration

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
