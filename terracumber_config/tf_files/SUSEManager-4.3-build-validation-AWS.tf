
// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-43/job/SUSEManager-432-AWS"
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
  default = "Results Manager4.3-WS-MU $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Manager4.3-AWS-MU: Environment setup failed"
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

variable "REGION" {
  type = string
  default = null
}

variable "MIRROR"{
  type = string
  default = null
}

variable "AVAILABILITY_ZONE" {
  type = string
  default = null
}

variable "KEY_FILE" {
  type = string
  default = "/home/jenkins/.ssh/testing-suma.pem"
}

variable "KEY_NAME" {
  type = string
  default = "testing-suma"
}

variable "SERVER_REGISTRATION_CODE" {
  type = string
  default = null
}

variable "PROXY_REGISTRATION_CODE" {
  type = string
  default = null
}

variable "SLES_REGISTRATION_CODE" {
  type = string
  default = null
}

variable "ALLOWED_IPS" {
  type = list(string)
  default = []
}

variable "NAME_PREFIX" {
  type = string
  default = null
}

provider "aws" {
  region     = var.REGION
}

module "base" {
  source = "./modules/base"

  cc_username              = var.SCC_USER
  cc_password              = var.SCC_PASSWORD
  name_prefix              = var.NAME_PREFIX
  mirror                   = var.MIRROR
  testsuite                = true
  use_avahi                = false
  use_eip_bastion          = false

  provider_settings = {
    availability_zone = var.AVAILABILITY_ZONE
    region            = var.REGION
    ssh_allowed_ips   = var.ALLOWED_IPS
    key_name          = var.KEY_NAME
    key_file          = var.KEY_FILE
  }
}

module "mirror" {
  source = "./modules/mirror"
  base_configuration = module.base.configuration
  disable_cron = true
  provider_settings = {
    public_instance = true
  }
  image = "opensuse155o"
}

module "server" {
  source                     = "./modules/server"
  base_configuration = merge(module.base.configuration,
  {
    mirror = null
  })
  name                       = "server"
  product_version            = "4.3-released"
  repository_disk_size       = 1500
  server_registration_code   = var.SERVER_REGISTRATION_CODE

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
  use_os_released_updates        = false
  disable_download_tokens        = false
  disable_auto_bootstrap         = true
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "m6a.xlarge"
  }

  //server_additional_repos

}

module "proxy" {

  source                    = "./modules/proxy"
  base_configuration        = module.base.configuration
  server_configuration      = module.server.configuration
  product_version           = "4.3-released"
  name                      = "proxy"
  proxy_registration_code   = var.PROXY_REGISTRATION_CODE

  auto_register             = false
  auto_connect_to_master    = false
  download_private_ssl_key  = false
  install_proxy_pattern     = false
  auto_configure            = false
  generate_bootstrap_script = false
  publish_private_ssl_key   = false
  use_os_released_updates   = true
  proxy_containerized       = false
  ssh_key_path              = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "c6i.large"
  }

  //proxy_additional_repos

}


module "sles12sp4-client" {
  source             = "./modules/client"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "cli-sles12sp4"
  image              = "sles12sp4"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles12sp5-client" {
  source             = "./modules/client"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "cli-sles12sp5"
  image              = "sles12sp5"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp2-client" {
  source             = "./modules/client"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "cli-sles15sp2"
  image              = "sles15sp2o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp4-client" {

  source             = "./modules/client"
  base_configuration = module.base.configuration
  name                 = "cli-sles15sp4"
  image                = "sles15sp4o"
  product_version    = "4.3-released"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

  //sle15sp4-client_additional_repos
}

module "sles15sp3-client" {

  source             = "./modules/client"
  base_configuration = module.base.configuration
  name                 = "cli-sles15sp3"
  image                = "sles15sp3o"
  product_version    = "4.3-released"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

  //sle15sp3-client_additional_repos
}

module "ubuntu2004-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-ubuntu2004"
  image              = "ubuntu2004"
  server_configuration = module.server.configuration
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  provider_settings = {
    instance_type = "t3a.medium"
  }
}

//module "debian11-minion" {
//  source             = "./modules/minion"
//  base_configuration = module.base.configuration
//  product_version    = "4.3-released"
//  name               = "min-debian11"
//  image              = "debian11"
//  server_configuration = module.server.configuration
//  auto_connect_to_master  = false
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  provider_settings = {
//    instance_type = "t3a.medium"
//  }
//}

//module "debian12-minion" {
//  source             = "./modules/minion"
//  base_configuration = module.base.configuration
//  product_version    = "4.3-released"
//  name               = "min-debian12"
//  image              = "debian12"
//  server_configuration = module.server.configuration
//  auto_connect_to_master  = false
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  provider_settings = {
//    instance_type = "t3a.medium"
//  }
//
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
//}

module "rocky8-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-rocky8"
  image              = "rocky8"
  server_configuration = module.server.configuration
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles12sp4-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles12sp4"
  image              = "sles12sp4"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles12sp5-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles12sp5"
  image              = "sles12sp5"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp2-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp2"
  image              = "sles15sp2o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp4-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp4"
  image              = "sles15sp4o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

  //sle15sp4-minion_additional_repos

}

module "sles15sp3-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp3"
  image              = "sles15sp3o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

  //sle15sp3-minion_additional_repos

}

module "ubuntu2004-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-ubuntu2004"
  image              = "ubuntu2004"
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  provider_settings = {
    instance_type = "t3a.medium"
  }
}

//module "debian11-sshminion" {
//  source             = "./modules/sshminion"
//  base_configuration = module.base.configuration
//  product_version    = "4.3-released"
//  name               = "minssh-debian11"
//  image              = "debian11"
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  provider_settings = {
//    instance_type = "t3a.medium"
//  }
//}

//module "debian12-sshminion" {
//  source             = "./modules/sshminion"
//  base_configuration = module.base.configuration
//  product_version    = "4.3-released"
//  name               = "minssh-debian12"
//  image              = "debian12"
//  use_os_released_updates = false
//  ssh_key_path            = "./salt/controller/id_rsa.pub"
//
//  provider_settings = {
//    instance_type = "t3a.medium"
//  }
//
//  additional_packages = [ "venv-salt-minion" ]
//  install_salt_bundle = true
//}

module "rocky8-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-rocky8"
  image              = "rocky8"
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true

  provider_settings = {
    instance_type = "t3a.medium"
  }

}

module "sles12sp4-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles12sp4"
  image              = "sles12sp4"
  use_os_released_updates = false
  sles_registration_code = var.SLES_REGISTRATION_CODE
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles12sp5-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles12sp5"
  image              = "sles12sp5"
  use_os_released_updates = false
  sles_registration_code = var.SLES_REGISTRATION_CODE
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

module "sles15sp2-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp2"
  image              = "sles15sp2o"
  sles_registration_code = var.SLES_REGISTRATION_CODE
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }
}


module "sles15sp4-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp4"
  image              = "sles15sp4o"
  sles_registration_code = var.SLES_REGISTRATION_CODE
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

}

module "sles15sp3-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp3"
  image              = "sles15sp3o"
  sles_registration_code = var.SLES_REGISTRATION_CODE
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

}

module "rhel9-minion" {

  source             = "./modules/minion"
  base_configuration = module.base.configuration
  server_configuration = module.server.configuration
  product_version    = "4.3-released"
  name               = "min-rhel9"
  image              = "rhel9"
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  install_salt_bundle = true
  provider_settings = {
    instance_type = "t3a.medium"
  }

  //rhel9-minion_additional_repos

}

module "ubuntu2204-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-ubuntu2204"
  image              = "ubuntu2204"
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

}

module "ubuntu2204-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  server_configuration = module.server.configuration
  product_version    = "4.3-released"
  name               = "min-ubuntu2204"
  image              = "ubuntu2204"
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

  //ubuntu2204-minion_additional_repos

}

module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base.configuration
  name               = "ctl"
  provider_settings = {
    instance_type = "c6i.xlarge"
  }

  swap_file_size = null
  no_mirror = true
  is_using_build_image = false
  is_using_scc_repositories = true
  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration    = module.server.configuration
  proxy_configuration     = module.proxy.configuration

  sle12sp4_client_configuration    = module.sles12sp4-client.configuration
  sle12sp4_minion_configuration    = module.sles12sp4-minion.configuration
  sle12sp4_sshminion_configuration = module.sles12sp4-sshminion.configuration

  sle12sp5_client_configuration    = module.sles12sp5-client.configuration
  sle12sp5_minion_configuration    = module.sles12sp5-minion.configuration
  sle12sp5_sshminion_configuration = module.sles12sp5-sshminion.configuration


  sle15sp2_client_configuration    = module.sles15sp2-client.configuration
  sle15sp2_minion_configuration    = module.sles15sp2-minion.configuration
  sle15sp2_sshminion_configuration = module.sles15sp2-sshminion.configuration

  sle15sp3_client_configuration    = module.sles15sp3-client.configuration
  sle15sp3_minion_configuration    = module.sles15sp3-minion.configuration
  sle15sp3_sshminion_configuration = module.sles15sp3-sshminion.configuration

  sle15sp4_client_configuration    = module.sles15sp4-client.configuration
  sle15sp4_minion_configuration    = module.sles15sp4-minion.configuration
  sle15sp4_sshminion_configuration = module.sles15sp4-sshminion.configuration

  rocky8_minion_configuration    = module.rocky8-minion.configuration
  rocky8_sshminion_configuration = module.rocky8-sshminion.configuration

  ubuntu2004_minion_configuration    = module.ubuntu2004-minion.configuration
  ubuntu2004_sshminion_configuration = module.ubuntu2004-sshminion.configuration

  ubuntu2204_minion_configuration    = module.ubuntu2204-minion.configuration
  ubuntu2204_sshminion_configuration = module.ubuntu2204-sshminion.configuration

//  debian11_minion_configuration    = module.debian11-minion.configuration
//  debian11_sshminion_configuration = module.debian11-sshminion.configuration

//  debian12_minion_configuration    = module.debian12-minion.configuration
//  debian12_sshminion_configuration = module.debian12-sshminion.configuration

  rhel9_minion_configuration          = module.rhel9-minion.configuration

}

output "bastion_public_name" {
  value = lookup(module.base.configuration, "bastion_host", null)
}

output "aws_mirrors_private_name" {
  value = module.mirror.configuration.hostnames
}

output "aws_mirrors_public_name" {
  value = module.mirror.configuration.public_names
}

output "configuration" {
  value = {
    controller = module.controller.configuration
    bastion = {
      hostname = lookup(module.base.configuration, "bastion_host", null)
    }
  }
}
