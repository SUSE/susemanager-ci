
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.8.3"
    }
    feilong = {
      source = "bischoff/feilong"
      version = "0.0.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://${var.ENVIRONMENT_CONFIGURATION.base_core["hypervisor"]}/system"
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
  product_version   = var.ENVIRONMENT_CONFIGURATION.product_version
  name_prefix       = var.ENVIRONMENT_CONFIGURATION.name_prefix
  use_avahi         = false
  domain            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain
  images            = [ "sles12sp5o", "sles15sp3o", "sles15sp4o", "sles15sp5o", "sles15sp6o", "sles15sp7o", "slemicro51-ign", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "slemicro55o", "slmicro60o", "slmicro61o", "almalinux8o", "almalinux9o", "amazonlinux2023o", "centos7o", "libertylinux9o", "oraclelinux9o", "rocky8o", "rocky9o", "ubuntu2204o",
    "ubuntu2404o", "debian12o", "opensuse155o", "opensuse156o" ]

  mirror            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].mirror
  use_mirror_images = true

  testsuite         = true

  provider_settings = {
    pool               = var.ENVIRONMENT_CONFIGURATION.base_core["pool"]
    bridge             = var.ENVIRONMENT_CONFIGURATION.base_core["bridge"]
    additional_network = var.ENVIRONMENT_CONFIGURATION.base_core["additional_network"]
  }
}

module "base_arm" {
  providers = {
    libvirt = libvirt.suma-arm
  }

  source            = "./modules/base"

  cc_username       = var.SCC_USER
  cc_password       = var.SCC_PASSWORD
  product_version   = var.ENVIRONMENT_CONFIGURATION.product_version
  name_prefix       = var.ENVIRONMENT_CONFIGURATION.name_prefix
  use_avahi         = false
  domain            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain
  images            = [ "opensuse156armo" ]

  mirror            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].mirror
  use_mirror_images = true

  testsuite         = true

  provider_settings = {
    pool        = "ssd"
    bridge      = "br1"
  }
}

module "base_s390" {
  source            = "./backend_modules/feilong/base"

  name_prefix       = var.ENVIRONMENT_CONFIGURATION.name_prefix
  domain            = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain
  product_version   = var.ENVIRONMENT_CONFIGURATION.product_version

  testsuite         = true
}

module "server_containerized" {
  source             = "./modules/server_containerized"
  base_configuration = module.base_core.configuration
  name               = "server"
  image              = "slmicro61o"
  provider_settings  = {
    mac                = var.ENVIRONMENT_CONFIGURATION.mac["server_containerized"]
    memory             = 40960
    vcpu               = 10
  }
  runtime = "podman"
  container_repository  = var.SERVER_CONTAINER_REPOSITORY
  container_image       = var.SERVER_CONTAINER_IMAGE
  main_disk_size        = 100
  repository_disk_size  = 3072
  database_disk_size    = 150
  container_tag         = "latest"
  beta_enabled          = false
  server_mounted_mirror          = var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].mirror
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
  ssh_key_path                   = "./salt/controller/id_ed25519.pub"
  from_email                     = "root@suse.de"
  provision                      = true

  //server_additional_repos

}

module "proxy_containerized" {
  source             = "./modules/proxy_containerized"
  base_configuration = module.base_core.configuration
  name               = "proxy"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["proxy_containerized"]
    memory  = 4096
  }
  runtime                   = "podman"
  container_repository      = var.PROXY_CONTAINER_REPOSITORY
  container_tag             = "latest"
  auto_configure            = false
  ssh_key_path              = "./salt/controller/id_ed25519.pub"
  provision                 = true

  //proxy_additional_repos

}

module "sles12sp5_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "sles12sp5-minion"
  image              = "sles12sp5o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["sles12sp5_minion"]
    memory  = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles15sp3_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp3-minion"
  image              = "sles15sp3o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp3_minion"]
    memory  = 4096
  }


  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles15sp4_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp4-minion"
  image              = "sles15sp4o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp4_minion"]
    memory  = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles15sp5_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp5-minion"
  image              = "sles15sp5o"
  provider_settings  = {
    mac    = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp5_minion"]
    memory = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles15sp6_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp6-minion"
  image              = "sles15sp6o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp6_minion"]
    memory  = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles15sp7_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp7-minion"
  image              = "sles15sp7o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp7_minion"]
    memory  = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "alma8_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "alma8-minion"
  image              = "almalinux8o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["alma8_minion"]
    memory  = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "alma9_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "alma9-minion"
  image              = "almalinux9o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["alma9_minion"]
    memory  = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "amazon2023_minion" {
  source             = "./modules/minion"
  base_configuration
                     = module.base_core.configuration
  name               = "amazon2023-minion"
  image              = "amazonlinux2023o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["amazon2023_minion"]
    memory  = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "centos7_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "centos7-minion"
  image              = "centos7o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["centos7_minion"]
    memory  = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "liberty9_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "liberty9-minion"
  image              = "libertylinux9o"
  provider_settings  = {
    mac    = var.ENVIRONMENT_CONFIGURATION.mac["liberty9_minion"]
    memory = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

// module "openeuler2403_minion" {
//   source             = "./modules/minion"
//   base_configuration = module.base_core.configuration
//   name               = "openeuler2403-minion"
//   image              = "openeuler2403o"
//   provider_settings = {
//     mac                = var.ENVIRONMENT_CONFIGURATION.mac["openeuler2403_minion"]
//     memory             = 4096
//   }
//   auto_connect_to_master  = false
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
// }

module "oracle9_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "oracle9-minion"
  image              = "oraclelinux9o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["oracle9_minion"]
    memory  = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "rocky8_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "rocky8-minion"
  image              = "rocky8o"
  provider_settings  = {
    mac    = var.ENVIRONMENT_CONFIGURATION.mac["rocky8_minion"]
    memory = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "rocky9_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "rocky9-minion"
  image              = "rocky9o"
  provider_settings  = {
    mac    = var.ENVIRONMENT_CONFIGURATION.mac["rocky9_minion"]
    memory = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "ubuntu2204_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "ubuntu2204-minion"
  image              = "ubuntu2204o"
  provider_settings  = {
    mac    = var.ENVIRONMENT_CONFIGURATION.mac["ubuntu2204_minion"]
    memory = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "ubuntu2404_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "ubuntu2404-minion"
  image              = "ubuntu2404o"
  provider_settings  = {
    mac    = var.ENVIRONMENT_CONFIGURATION.mac["ubuntu2404_minion"]
    memory = 4096
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "debian12_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "debian12-minion"
  image              = "debian12o"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["debian12_minion"]
    memory  = 4096
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "opensuse156arm_minion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/minion"
  base_configuration = module.base_arm.configuration
  name               = "opensuse156arm-minion${var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].extension}"
  image              = "opensuse156armo"
  provider_settings = {
    mac                = var.ENVIRONMENT_CONFIGURATION.mac["opensuse156arm_minion"]
    overwrite_fqdn     = "${var.ENVIRONMENT_CONFIGURATION.name_prefix}opensuse156arm-minion.${var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain}"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles15sp5s390_minion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration

  name               = "sles15sp5s390-minion"
  image              = "s15s5-minimal-2part-xfs"

  provider_settings = {
    userid             = var.ENVIRONMENT_CONFIGURATION.s390["minion_userid"]
    mac                = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp5s390_minion"]
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

// This is an x86_64 SLES 15 SP5 minion (like sles15sp5-minion),
// dedicated to testing migration from OS Salt to Salt bundle
module "salt_migration_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "salt-migration-minion"
  image              = "sles15sp5o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["salt_migration_minion"]
    memory  = 4096
  }
  server_configuration = module.server_containerized.configuration
  auto_connect_to_master  = true
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  install_salt_bundle = false
}

module "slemicro51_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slemicro51-minion"
  image              = "slemicro51-ign"
  provider_settings  = {
    mac    = var.ENVIRONMENT_CONFIGURATION.mac["slemicro51_minion"]
    memory = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  // WORKAROUND: Does not work in sumaform, yet
  install_salt_bundle = false
}

module "slemicro52_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slemicro52-minion"
  image              = "slemicro52-ign"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["slemicro52_minion"]
    memory  = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  // WORKAROUND: Does not work in sumaform, yet
  install_salt_bundle = false
}

module "slemicro53_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slemicro53-minion"
  image              = "slemicro53-ign"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["slemicro53_minion"]
    memory  = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  // WORKAROUND: Does not work in sumaform, yet
  install_salt_bundle = false
}

module "slemicro54_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slemicro54-minion"
  image              = "slemicro54-ign"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["slemicro54_minion"]
    memory  = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  // WORKAROUND: Does not work in sumaform, yet
  install_salt_bundle = false
}

module "slemicro55_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slemicro55-minion"
  image              = "slemicro55o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["slemicro55_minion"]
    memory  = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

  // WORKAROUND: Does not work in sumaform, yet
  install_salt_bundle = false
}

module "slmicro60_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slmicro60-minion"
  image              = "slmicro60o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["slmicro60_minion"]
    memory  = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "slmicro61_minion" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "slmicro61-minion"
  image              = "slmicro61o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["slmicro61_minion"]
    memory  = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles12sp5_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "sles12sp5-sshminion"
  image              = "sles12sp5o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["sles12sp5_sshminion"]
    memory  = 4096
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]
}

module "sles15sp3_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp3-sshminion"
  image              = "sles15sp3o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp3_sshminion"]
    memory  = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles15sp4_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp4-sshminion"
  image              = "sles15sp4o"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp4_sshminion"]
    memory  = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles15sp5_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp5-sshminion"
  image              = "sles15sp5o"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp5_sshminion"]
    memory  = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles15sp6_sshminion" {

  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp6-sshminion"
  image              = "sles15sp6o"
  provider_settings  = {
    mac      = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp6_sshminion"]
    memory   = 4096
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles15sp7_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "sles15sp7-sshminion"
  image              = "sles15sp7o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp7_sshminion"]
    memory  = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "alma8_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "alma8-sshminion"
  image              = "almalinux8o"
  provider_settings  = {
    mac      = var.ENVIRONMENT_CONFIGURATION.mac["alma8_sshminion"]
    memory   = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "alma9_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "alma9-sshminion"
  image              = "almalinux9o"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["alma9_sshminion"]
    memory  = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "amazon2023_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "amazon2023-sshminion"
  image              = "amazonlinux2023o"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["amazon2023_sshminion"]
    memory  = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "centos7_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "centos7-sshminion"
  image              = "centos7o"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["centos7_sshminion"]
    memory  = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}


module "liberty9_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "liberty9-sshminion"
  image              = "libertylinux9o"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["liberty9_sshminion"]
    memory  = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

// module "openeuler2403_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "openeuler2403-sshminion"
//   image              = "openeuler2403o"
//   provider_settings = {
//     mac                = var.ENVIRONMENT_CONFIGURATION.mac["openeuler2403_sshminion"]
//     memory             = 4096
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
// }

module "oracle9_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "oracle9-sshminion"
  image              = "oraclelinux9o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["oracle9_sshminion"]
    memory  = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "rocky8_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "rocky8-sshminion"
  image              = "rocky8o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["rocky8_sshminion"]
    memory  = 4096

  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "rocky9_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "rocky9-sshminion"
  image              = "rocky9o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["rocky9_sshminion"]
    memory  = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "ubuntu2204_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "ubuntu2204-sshminion"
  image              = "ubuntu2204o"
  provider_settings  = {
    mac    = var.ENVIRONMENT_CONFIGURATION.mac["ubuntu2204_sshminion"]
    memory = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "ubuntu2404_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "ubuntu2404-sshminion"
  image              = "ubuntu2404o"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["ubuntu2404_sshminion"]
    memory  = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "debian12_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base_core.configuration
  name               = "debian12-sshminion"
  image              = "debian12o"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["debian12_sshminion"]
    memory  = 4096
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "opensuse156arm_sshminion" {
  providers = {
    libvirt = libvirt.suma-arm
  }
  source             = "./modules/sshminion"
  base_configuration = module.base_arm.configuration
  name               = "opensuse156arm-sshminion${var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].extension}"
  image              = "opensuse156armo"
  provider_settings = {
    mac                = var.ENVIRONMENT_CONFIGURATION.mac["opensuse156arm_sshminion"]
    overwrite_fqdn     = "${var.ENVIRONMENT_CONFIGURATION.name_prefix}opensuse156arm-sshminion.${var.PLATFORM_LOCATION_CONFIGURATION[var.LOCATION].domain}"
    memory             = 2048
    vcpu               = 2
    xslt               = file("../../susemanager-ci/terracumber_config/tf_files/common/tune-aarch64.xslt")
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "sles15sp5s390_sshminion" {
  source             = "./backend_modules/feilong/host"
  base_configuration = module.base_s390.configuration

  name               = "sles15sp5s390-sshminion"
  image              = "s15s5-minimal-2part-xfs"

  provider_settings = {
    userid             = var.ENVIRONMENT_CONFIGURATION.s390["shh_minion_userid"]
    mac                = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp5s390_sshminion"]
    ssh_user           = "sles"
    vswitch            = "VSUMA"
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro51_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slemicro51-sshminion"
//   image              = "slemicro51-ign"
//   provider_settings = {
//     mac                = var.ENVIRONMENT_CONFIGURATION.mac["slemicro51_sshminion"]
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro52_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slemicro52-sshminion"
//   image              = "slemicro52-ign"
//   provider_settings = {
//     mac                = var.ENVIRONMENT_CONFIGURATION.mac["slemicro52_sshminion"]
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro53_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slemicro53-sshminion"
//   image              = "slemicro53-ign"
//   provider_settings = {
//     mac                = var.ENVIRONMENT_CONFIGURATION.mac["slemicro53_sshminion"]
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
// }

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro54_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slemicro54-sshminion"
//   image              = "slemicro54-ign"
//   provider_settings = {
//     mac                = var.ENVIRONMENT_CONFIGURATION.mac["slemicro54_sshminion"]
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
//
//
//
//}

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slemicro55_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slemicro55-sshminion"
//   image              = "slemicro55o"
//   provider_settings = {
//     mac                = var.ENVIRONMENT_CONFIGURATION.mac["slemicro55_sshminion"]
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
//
//
//}

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slmicro60_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slmicro60-sshminion"
//   image              = "slmicro60o"
//   provider_settings = {
//     mac                = var.ENVIRONMENT_CONFIGURATION.mac["slmicro60_sshminion"]
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
//
//
//}

//  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
// module "slmicro61_sshminion" {
//   source             = "./modules/sshminion"
//   base_configuration = module.base_core.configuration
//   name               = "slmicro61-sshminion"
//   image              = "slmicro61o"
//   provider_settings = {
//     mac                = var.ENVIRONMENT_CONFIGURATION.mac["slmicro61_sshminion"]
//     memory             = 2048
//   }
//   use_os_released_updates = false
//   ssh_key_path            = "./salt/controller/id_ed25519.pub"
//
//
//}

module "sles15sp6_buildhost" {
  source             = "./modules/build_host"
  base_configuration = module.base_core.configuration
  name               = "sles15sp6-build"
  image              = "sles15sp6o"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp6_buildhost"]
    memory  = 2048
    vcpu    = 2
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

}

module "sles15sp7_buildhost" {
  source             = "./modules/build_host"
  base_configuration = module.base_core.configuration
  name               = "sles15sp7-build"
  image              = "sles15sp7o"
  provider_settings = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["sles15sp7_buildhost"]
    memory  = 2048
    vcpu    = 2
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"

}

module "sles15sp6_terminal" {
  source             = "./modules/pxe_boot"
  base_configuration = module.base_core.configuration
  name               = "sles15sp6-terminal"
  image              = "sles15sp6o"
  provider_settings = {
    memory             = 2048
    vcpu               = 2
    manufacturer       = "HP"
    product            = "ProLiant DL360 Gen9"
  }
  private_ip         = 6
  private_name       = "sle15sp6terminal"
}

module "sles15sp7_terminal" {
  source             = "./modules/pxe_boot"
  base_configuration = module.base_core.configuration
  name               = "sles15sp7-terminal"
  image              = "sles15sp7o"
  provider_settings = {
    memory             = 2048
    vcpu               = 2
    manufacturer       = "HP"
    product            = "ProLiant DL580 Gen9"
  }
  private_ip         = 7
  private_name       = "sle15sp7terminal"
}

module "dhcp_dns" {
  source             = "./modules/dhcp_dns"
  base_configuration = module.base_core.configuration
  name               = "dhcp-dns"
  image              = "opensuse155o"
  private_hosts = [
    module.proxy_containerized.configuration,
    module.sles15sp6_terminal.configuration,
    module.sles15sp7_terminal.configuration
  ]
  hypervisor = {
    host        = "suma-10.mgr.suse.de"
    user        = "root"
    private_key = file("~/.ssh/id_ed25519")
  }
}

module "monitoring_server" {
  source             = "./modules/minion"
  base_configuration = module.base_core.configuration
  name               = "monitoring"
  image              = "sles15sp7o"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["monitoring_server"]
    memory  = 2048
  }

  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_ed25519.pub"
}

module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base_core.configuration
  name               = "controller"
  provider_settings  = {
    mac     = var.ENVIRONMENT_CONFIGURATION.mac["controller"]
    memory  = 16384
    vcpu    = 8
  }
  swap_file_size = null
  beta_enabled   = false

  cc_ptf_username = var.SCC_PTF_USER
  cc_ptf_password = var.SCC_PTF_PASSWORD

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/temporary"

  server_configuration = module.server_containerized.configuration

  proxy_configuration  = module.proxy_containerized.configuration

  sle12sp5_minion_configuration    = module.sles12sp5_minion.configuration
  sle12sp5_sshminion_configuration = module.sles12sp5_sshminion.configuration

  sle15sp3_minion_configuration    = module.sles15sp3_minion.configuration
  sle15sp3_sshminion_configuration = module.sles15sp3_sshminion.configuration

  sle15sp4_minion_configuration    = module.sles15sp4_minion.configuration
  sle15sp4_sshminion_configuration = module.sles15sp4_sshminion.configuration

  sle15sp5_minion_configuration    = module.sles15sp5_minion.configuration
  sle15sp5_sshminion_configuration = module.sles15sp5_sshminion.configuration

  sle15sp6_minion_configuration    = module.sles15sp6_minion.configuration
  sle15sp6_sshminion_configuration = module.sles15sp6_sshminion.configuration

  sle15sp7_minion_configuration    = module.sles15sp7_minion.configuration
  sle15sp7_sshminion_configuration = module.sles15sp7_sshminion.configuration

  alma8_minion_configuration    = module.alma8_minion.configuration
  alma8_sshminion_configuration = module.alma8_sshminion.configuration

  alma9_minion_configuration    = module.alma9_minion.configuration
  alma9_sshminion_configuration = module.alma9_sshminion.configuration

  amazon2023_minion_configuration    = module.amazon2023_minion.configuration
  amazon2023_sshminion_configuration = module.amazon2023_sshminion.configuration

  centos7_minion_configuration    = module.centos7_minion.configuration
  centos7_sshminion_configuration = module.centos7_sshminion.configuration

  liberty9_minion_configuration    = module.liberty9_minion.configuration
  liberty9_sshminion_configuration = module.liberty9_sshminion.configuration

  // openeuler2403_minion_configuration    = module.openeuler2403_minion.configuration
  // openeuler2403_sshminion_configuration = module.openeuler2403_sshminion.configuration

  oracle9_minion_configuration    = module.oracle9_minion.configuration
  oracle9_sshminion_configuration = module.oracle9_sshminion.configuration

  // rhel9 is tested only in AWS for legal reasons

  rocky8_minion_configuration    = module.rocky8_minion.configuration
  rocky8_sshminion_configuration = module.rocky8_sshminion.configuration

  rocky9_minion_configuration    = module.rocky9_minion.configuration
  rocky9_sshminion_configuration = module.rocky9_sshminion.configuration

  ubuntu2204_minion_configuration    = module.ubuntu2204_minion.configuration
  ubuntu2204_sshminion_configuration = module.ubuntu2204_sshminion.configuration

  ubuntu2404_minion_configuration    = module.ubuntu2404_minion.configuration
  ubuntu2404_sshminion_configuration = module.ubuntu2404_sshminion.configuration

  debian12_minion_configuration    = module.debian12_minion.configuration
  debian12_sshminion_configuration = module.debian12_sshminion.configuration

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

  slmicro61_minion_configuration    = module.slmicro61_minion.configuration
  //  WORKAROUND until https://bugzilla.suse.com/show_bug.cgi?id=1208045 gets fixed
  //  slmicro61_sshminion_configuration = module.slmicro61_sshminion.configuration

  sle15sp6_buildhost_configuration = module.sles15sp6_buildhost.configuration
  sle15sp7_buildhost_configuration = module.sles15sp7_buildhost.configuration

  sle15sp6_terminal_configuration = module.sles15sp6_terminal.configuration
  sle15sp7_terminal_configuration = module.sles15sp7_terminal.configuration

  monitoringserver_configuration = module.monitoring_server.configuration
}

output "configuration" {
  value = {
    controller  = module.controller.configuration
    server      = module.server_containerized.configuration
  }
}