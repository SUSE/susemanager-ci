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

variable "CONTAINER_REPOSITORY" {
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
  connector   = "https://feilong.mgr.suse.de"
  admin_token = var.ZVM_ADMIN_TOKEN
  local_user  = "jenkins@jenkins-worker.mgr.suse.de"
}

module "base_core" {
  source            = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = "uyuni-master"
  name_prefix       = "uyuni-bv-master-"
  use_avahi         = false
  domain            = "mgr.suse.de"
  images            = [ "sles12sp5o", "sles15sp2o", "sles15sp3o", "sles15sp4o", "sles15sp5o", "sles15sp6o", "slemicro51-ign", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "slemicro55o", "slmicro60o", "almalinux8o", "almalinux9o", "centos7o", "libertylinux9o", "oraclelinux9o", "rocky8o", "rocky9o", "ubuntu2004o", "ubuntu2204o", "ubuntu2404o", "debian11o", "debian12o", "opensuse155o", "opensuse156o", "leapmicro55o" ]

  mirror            = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images = true

  testsuite         = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br0"
    additional_network = "192.168.100.0/24"
  }
}

module "base_arm" {
  providers = {
    libvirt = libvirt.suma-arm
  }

  source            = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = "uyuni-master"
  name_prefix       = "uyuni-bv-master-"
  use_avahi         = false
  domain            = "mgr.suse.de"
  images            = [ "opensuse155armo", "opensuse156armo" ]

  mirror            = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images = true

  testsuite         = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br0"
  }
}

module "base_s390" {
  source = "./backend_modules/feilong/base"

  name_prefix       = "uyuni-bv-master-"
  domain            = "mgr.suse.de"
  product_version   = "uyuni-master"

  testsuite         = true
}

module "server_containerized" {
  source             = "./modules/server_containerized"
  base_configuration = module.base_core.configuration
  name               = "server"
  image              = "leapmicro55o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a1"
    memory             = 40960
    vcpu               = 10
    data_pool          = "ssd"
  }

  server_mounted_mirror = "minima-mirror-ci-bv.mgr.suse.de"
  main_disk_size        = 100
  repository_disk_size  = 3072
  database_disk_size    = 150

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

  runtime               = "podman"
  container_repository  = var.CONTAINER_REPOSITORY
  container_tag         = "latest"

  //server_additional_repos

}

module "proxy_containerized" {
  source             = "./modules/proxy_containerized"
  base_configuration = module.base_core.configuration
  name               = "proxy"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a2"
    memory             = 4096
  }

  runtime                   = "podman"
  container_repository      = var.CONTAINER_REPOSITORY
  container_tag             = "latest"
  auto_configure            = false
  ssh_key_path              = "./salt/controller/id_rsa.pub"
}

// No traditional clients in Uyuni

module "sles12sp5_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "sles12sp5-minion"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b1"
    memory             = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp2_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp2-minion"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b4"
    memory             = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp3_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp3-minion"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b5"
    memory             = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp4-minion"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b6"
    memory             = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp5_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp5-minion"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b2"
    memory             = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp6_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp6-minion"
  image              = "sles15sp6o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b0"
    memory             = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "alma8_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "alma8-minion"
  image              = "almalinux8o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b9"
    memory             = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "alma9_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "alma9-minion"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c2"
    memory             = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "centos7_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "centos7-minion"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b7"
    memory             = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "liberty9_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "liberty9-minion"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c5"
    memory             = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "oracle9_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "oracle9-minion"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c3"
    memory             = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "rocky8_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "rocky8-minion"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:b8"

    memory             = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "rocky9_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "rocky9-minion"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c1"
    memory             = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu2004_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "ubuntu2004-minion"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:ba"
    memory             = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

}

module "ubuntu2204_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "ubuntu2204-minion"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:bb"
    memory             = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu2404_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "ubuntu2404-minion"
  image              = "ubuntu2404o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:bd"
    memory             = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian11_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "debian11-minion"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:be"
    memory             = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian12_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "debian12-minion"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:bc"
    memory             = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "opensuse155arm_minion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  name               = "opensuse155arm-minion-nue"
  image              = "opensuse155armo"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c0"
    overwrite_fqdn     = "uyuni-bv-master-opensuse155arm-minion.mgr.suse.de"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "opensuse156arm_minion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  name               = "opensuse156arm-minion-nue"
  image              = "opensuse156armo"
  provider_settings = {
    mac                = "aa:b2:93:02:01:ce"
    overwrite_fqdn     = "uyuni-bv-master-opensuse156arm-minion.mgr.suse.de"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp5s390_minion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration

  name               = "sles15sp5s390-minion"
  image              = "s15s5-minimal-2part-xfs"

  provider_settings = {
    userid             = "UYMMINUE"
    mac                = "02:3a:fc:42:00:2c"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "salt_migration_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "salt-migration-minion"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:cf"
    memory             = 4096
  }

  server_configuration = {
    hostname = "uyuni-bv-master-proxy.mgr.suse.de"
  }
  auto_connect_to_master  = true
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  install_salt_bundle = false
}

module "slemicro51_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slemicro51-minion"
  image              = "slemicro51-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c6"
    memory             = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro52_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slemicro52-minion"
  image              = "slemicro52-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c7"
    memory             = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro53_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slemicro53-minion"
  image              = "slemicro53-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c8"
    memory             = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro54_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slemicro54-minion"
  image              = "slemicro54-ign"
  provider_settings = {
    mac                = "aa:b2:93:02:01:c9"
    memory             = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slemicro55_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slemicro55-minion"
  image              = "slemicro55o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:ca"
    memory             = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "slmicro60_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slmicro60-minion"
  image              = "slmicro60o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:cb"
    memory             = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
// WORKAROUND: Does not work in sumaform, yet
//  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = false
}

module "sles12sp5_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "sles12sp5-sshminion"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d1"
    memory             = 4096
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]
}

module "sles15sp2_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp2-sshminion"
  image              = "sles15sp2o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d4"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp3_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp3-sshminion"
  image              = "sles15sp3o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d5"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp4-sshminion"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d6"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp5_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp5-sshminion"
  image              = "sles15sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d2"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp6_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp6-sshminion"
  image              = "sles15sp6o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d0"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "alma8_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "alma8-sshminion"
  image              = "almalinux8o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d9"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

}

module "alma9_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "alma9-sshminion"
  image              = "almalinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:e2"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "centos7_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "centos7-sshminion"
  image              = "centos7o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d7"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "liberty9_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "liberty9-sshminion"
  image              = "libertylinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:e5"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "oracle9_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "oracle9-sshminion"
  image              = "oraclelinux9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:e3"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "rocky8_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "rocky8-sshminion"
  image              = "rocky8o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:d8"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "rocky9_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "rocky9-sshminion"
  image              = "rocky9o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:e1"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu2004_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "ubuntu2004-sshminion"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:da"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

}

module "ubuntu2204_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "ubuntu2204-sshminion"
  image              = "ubuntu2204o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:db"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "ubuntu2404_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "ubuntu2404-sshminion"
  image              = "ubuntu2404o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:dd"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian11_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "debian11-sshminion"
  image              = "debian11o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:de"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "debian12_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "debian12-sshminion"
  image              = "debian12o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:dc"
    memory             = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "opensuse155arm_sshminion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_arm.configuration
  name               = "opensuse155arm-sshminion-nue"
  image              = "opensuse155armo"
  provider_settings = {
    mac                = "aa:b2:93:02:01:e0"
    overwrite_fqdn     = "uyuni-bv-master-opensuse155arm-sshminion.mgr.suse.de"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "opensuse156arm_sshminion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_arm.configuration
  name               = "opensuse156arm-sshminion-nue"
  image              = "opensuse156armo"
  provider_settings = {
    mac                = "aa:b2:93:02:01:ee"
    overwrite_fqdn     = "uyuni-bv-master-opensuse156arm-sshminion.mgr.suse.de"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp5s390_sshminion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration

  name               = "sles15sp5s390-sshminion"
  image              = "s15s5-minimal-2part-xfs"

  provider_settings = {
    userid             = "UYMSSNUE"
    mac                = "02:3a:fc:42:00:2d"
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro51_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slemicro51-sshminion"
//   image              = "slemicro51-ign"
//   provider_settings = {
//     mac                = "aa:b2:93:02:01:e6"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro52_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slemicro52-sshminion"
//   image              = "slemicro52-ign"
//   provider_settings = {
//     mac                = "aa:b2:93:02:01:e7"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro53_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slemicro53-sshminion"
//   image              = "slemicro53-ign"
//   provider_settings = {
//     mac                = "aa:b2:93:02:01:e8"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro54_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slemicro54-sshminion"
//   image              = "slemicro54-ign"
//   provider_settings = {
//     mac                = "aa:b2:93:02:01:e9"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro55_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slemicro55-sshminion"
//   image              = "slemicro55o"
//   provider_settings = {
//     mac                = "aa:b2:93:02:01:ea"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slmicro60_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slmicro60-sshminion"
//   image              = "slmicro60o"
//   provider_settings = {
//     mac                = "aa:b2:93:02:01:eb"
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_rsa.pub"
// }

module "sles12sp5_buildhost" {
  source             = "./modules/build_host"
  base_configuration = module.base_core.configuration
  name               = "sles12sp5-build"
  image              = "sles12sp5o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a4"
    memory             = 2048
    vcpu               = 2
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles12sp5_terminal" {
  source             = "./modules/pxe_boot"
  base_configuration = module.base_core.configuration
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


module "sles15sp4_buildhost" {
  source             = "./modules/build_host"
  base_configuration = module.base_core.configuration
  name               = "sles15sp4-build"
  image              = "sles15sp4o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a5"
    memory             = 2048
    vcpu               = 2
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp4_terminal" {
  source             = "./modules/pxe_boot"
  base_configuration = module.base_core.configuration
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

module "monitoring_server" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "monitoring"
  image              = "opensuse155o"
  provider_settings = {
    mac                = "aa:b2:93:02:01:a3"
    memory             = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base_core.configuration
  name               = "controller"
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

  // rhel9 is tested only in AWS for legal reasons

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
    controller  = module.controller.configuration
    server      = module.server_containerized.configuration
  }
}
