// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-qe/job/manager-5.0-qe-build-validation-NUE"
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
      version = "0.0.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://suma-06.mgr.suse.de/system"
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
  name_prefix = "suma-bv-50-"
  use_avahi   = false
  domain      = "mgr.suse.de"
  images      = [ "sles12sp5o", "sles15sp1o", "sles15sp2o", "sles15sp3o", "sles15sp4o", "sles15sp5o", "slemicro51-ign", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "slemicro55o", "almalinux8o", "almalinux9o", "centos7o", "libertylinux9o", "oraclelinux9o", "rocky8o", "rocky9o", "ubuntu2004o", "ubuntu2204o", "debian11o", "debian12o", "opensuse155o" ]


  mirror = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br0"
    additional_network = "192.168.50.0/24"
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
  domain      = "mgr.suse.de"
  images      = [ "opensuse154armo", "opensuse155armo" ]

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

  name_prefix = "suma-bv-50-"
  domain      = "mgr.suse.de"

  testsuite   = true
}

module "server_containerized" {
  source             = "./modules/server_containerized"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "srv"
  image              = "slemicro55o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:51"
    memory             = 40960
    vcpu               = 10
    data_pool          = "ssd"
  }
  main_disk_size = 3000
  runtime = "podman"
// WORKAROUND
// We want to test the most recent code right now until the submissions for Beta 2 are ready
//  container_repository = "registry.suse.de/suse/sle-15-sp6/update/products/manager50/containerfile/suse/manager/5.0/x86_64"
  container_repository = "registry.suse.de/devel/galaxy/manager/head/containerfile/suse/manager/5.0/x86_64"


  server_mounted_mirror          = "minima-mirror-ci-bv.mgr.suse.de"
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
  source             = "./modules/proxy_containerized"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "pxy"
  provider_settings = {
    mac                = "aa:b2:92:42:00:52"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
    username = "admin"
    password = "admin"
  }
  runtime = "podman"
  auto_configure            = false
  ssh_key_path              = "./salt/controller/id_rsa.pub"
}

module "sles12sp5-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:61"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp1-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:63"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp2-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:64"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp3-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:65"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp4-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:66"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp5-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:62"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "alma8-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-alma8"
  image              = "almalinux8o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:69"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
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
  product_version    = "head"
  name               = "min-alma9"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:72"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
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
  product_version    = "head"
  name               = "min-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:67"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
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
  product_version    = "head"
  name               = "min-liberty9"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:75"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
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
  product_version    = "head"
  name               = "min-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:73"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
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
  product_version    = "head"
  name               = "min-rocky8"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:68"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
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
  product_version    = "head"
  name               = "min-rocky9"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:71"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
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
  product_version    = "head"
  name               = "min-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:6a"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
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
  product_version    = "head"
  name               = "min-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:6b"
    memory             = 4096
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "debian11-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-debian11"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:6e"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "debian12-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-debian12"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:6c"
    memory             = 4096
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
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
  product_version    = "head"
  name               = "nue-min-opensuse154arm"
  image              = "opensuse154armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:6f"
    overwrite_fqdn     = "suma-bv-50-min-opensuse154arm.mgr.suse.de"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "opensuse155arm-minion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  product_version    = "head"
  name               = "nue-min-opensuse155arm"
  image              = "opensuse155armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:70"
    overwrite_fqdn     = "suma-bv-50-min-opensuse155arm.mgr.suse.de"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp5s390-minion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration

  name               = "min-sles15sp5s390"
  image              = "s15s5-minimal-2part-xfs"

  provider_settings = {
    userid             = "S50MINUE"
    mac                = "02:3a:fc:42:00:2a"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "slemicro51-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-slemicro51"
  image              = "slemicro51-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:76"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
}

module "slemicro52-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-slemicro52"
  image              = "slemicro52-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:77"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
}

module "slemicro53-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-slemicro53"
  image              = "slemicro53-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:78"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
}

module "slemicro54-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-slemicro54"
  image              = "slemicro54-ign"
  provider_settings = {
    mac                = "aa:b2:92:42:00:79"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
}

module "slemicro55-minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "min-slemicro55"
  image              = "slemicro55o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:7a"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
}

module "sles12sp5-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "minssh-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:81"
    memory             = 4096
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp1-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "minssh-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:83"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp2-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "minssh-sles15sp2"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:84"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp3-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "minssh-sles15sp3"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:85"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp4-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "minssh-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:86"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp5-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "minssh-sles15sp5"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:82"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "alma8-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "minssh-alma8"
  image              = "almalinux8o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:89"
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
  product_version    = "head"
  name               = "minssh-alma9"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:92"
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
  product_version    = "head"
  name               = "minssh-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:87"
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
  product_version    = "head"
  name               = "minssh-liberty9"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:95"
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
  product_version    = "head"
  name               = "minssh-oracle9"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:93"
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
  product_version    = "head"
  name               = "minssh-rocky8"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:88"
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
  product_version    = "head"
  name               = "minssh-rocky9"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:91"
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
  product_version    = "head"
  name               = "minssh-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:8a"
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
  product_version    = "head"
  name               = "minssh-ubuntu2204"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:8b"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "debian11-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "minssh-debian11"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:8e"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "debian12-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "minssh-debian12"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:8c"
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
  product_version    = "head"
  name               = "nue-minssh-opensuse154arm"
  image              = "opensuse154armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:8f"
    overwrite_fqdn     = "suma-bv-50-minssh-opensuse154arm.mgr.suse.de"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "opensuse155arm-sshminion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_arm.configuration
  product_version    = "head"
  name               = "nue-minssh-opensuse155arm"
  image              = "opensuse155armo"
  provider_settings = {
    mac                = "aa:b2:92:42:00:90"
    overwrite_fqdn     = "suma-bv-50-minssh-opensuse155arm.mgr.suse.de"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

module "sles15sp5s390-sshminion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration

  name               = "minssh-sles15sp5s390"
  image              = "s15s3-jeos-1part-ext4"

  provider_settings = {
    userid             = "S50SSNUE"
    mac                = "02:3a:fc:42:00:2b"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
}

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro51-sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   product_version    = "head"
//   name               = "minssh-slemicro51"
//   image              = "slemicro51-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:42:00:96"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro52-sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   product_version    = "head"
//   name               = "minssh-slemicro52"
//   image              = "slemicro52-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:42:00:97"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro53-sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   product_version    = "head"
//   name               = "minssh-slemicro53"
//   image              = "slemicro53-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:42:00:98"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro54-sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   product_version    = "head"
//   name               = "minssh-slemicro54"
//   image              = "slemicro54-ign"
//   provider_settings = {
//     mac                = "aa:b2:92:42:00:99"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
//}

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro55-sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   product_version    = "head"
//   name               = "minssh-slemicro55"
//   image              = "slemicro55o"
//   provider_settings = {
//     mac                = "aa:b2:92:42:00:9a"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
//}

module "sles12sp5-buildhost" {
  source             = "./modules/build_host"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "build-sles12sp5"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:54"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
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
  product_version    = "head"
  name               = "build-sles15sp4"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:55"
    memory             = 2048
    vcpu               = 2
  }
  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
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

module "dhcp-dns" {
  source             = "./modules/dhcp_dns"
  base_configuration = module.base_core.configuration
  name               = "dhcp-dns"
  image              = "opensuse155o"
  private_hosts      = [ module.proxy_containerized.configuration, module.sles12sp5-terminal.configuration, module.sles15sp4-terminal.configuration ]
}

module "monitoring-server" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  product_version    = "head"
  name               = "monitoring"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:92:42:00:53"
    memory             = 2048
  }

  server_configuration = {
    hostname = "suma-bv-50-srv.mgr.suse.de"
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
  name               = "ctl"
  provider_settings = {
    mac                = "aa:b2:92:42:00:50"
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

  proxy_configuration  = module.proxy_containerized.configuration

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

  alma8_minion_configuration    = module.alma8-minion.configuration
  alma8_sshminion_configuration = module.alma8-sshminion.configuration

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

  opensuse154arm_minion_configuration    = module.opensuse154arm-minion.configuration
  opensuse154arm_sshminion_configuration = module.opensuse154arm-sshminion.configuration

  opensuse155arm_minion_configuration    = module.opensuse155arm-minion.configuration
  opensuse155arm_sshminion_configuration = module.opensuse155arm-sshminion.configuration

  sle15sp5s390_minion_configuration    = module.sles15sp5s390-minion.configuration
  sle15sp5s390_sshminion_configuration = module.sles15sp5s390-sshminion.configuration

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
