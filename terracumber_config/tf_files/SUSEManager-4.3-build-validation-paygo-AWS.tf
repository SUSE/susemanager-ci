
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


// sumaform specific variables
variable "SCC_USER" {
  type = string
  default = null
}

variable "SCC_PASSWORD" {
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

  name_prefix              = var.NAME_PREFIX
  mirror                   = var.MIRROR
  testsuite                = true
  use_avahi                = false
  use_eip_bastion          = false
  is_server_paygo_instance = true
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
  product_version            = "paygo"
  image                      = "suma-server-43-ltd-paygo"
  main_disk_size             = 200
  repository_disk_size       = 1500
  database_disk_size         = 0

  auto_accept                    = false
  monitored                      = false
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
  large_deployment               = true
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
  image = "suma-proxy-43-byos"


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

}

module "sles12sp5_paygo_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "paygo"
  name               = "min-sles12sp5-paygo"
  image              = "sles12sp5-paygo"
  provider_settings = {
    instance_type = "t3a.medium"
  }
  server_configuration = module.server.configuration
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  additional_packages = [ "python-instance-billing-flavor-check" ]
}

module "sles15sp5_paygo_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "paygo"
  name               = "min-sles15sp5-paygo"
  image              = "sles15sp5-paygo"
  provider_settings = {
    instance_type = "t3a.medium"
  }
  server_configuration = module.server.configuration
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  additional_packages = [ "python-instance-billing-flavor-check" ]
}

module "sles15sp6_paygo_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "paygo"
  name               = "min-sles15sp6-paygo"
  image              = "sles15sp6-paygo"
  provider_settings = {
    instance_type = "t3a.medium"
  }
  server_configuration = module.server.configuration
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  additional_packages = [ "python-instance-billing-flavor-check" ]
}

module "slesforsap15sp5_paygo_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "paygo"
  name               = "min-slesforsap15sp5-paygo"
  image              = "slesforsap15sp5-paygo"
  provider_settings = {
    instance_type = "t3.large"
  }
  server_configuration = module.server.configuration
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  additional_packages = [ "python-instance-billing-flavor-check" ]
}


module "sles12sp5_client" {
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
  additional_packages = [ "chrony" ]

}

module "sles15sp4_client" {

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

}

module "sles12sp5_minion" {
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
  additional_packages = [ "chrony" ]

}

module "sles15sp4_byos_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp4-byos"
  image              = "sles15sp4o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

}

module "sles15sp4_minion" {
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

}

module "sles15sp5_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp5"
  image              = "sles15sp5o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

}

module "sles15sp6_minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles15sp6"
  image              = "sles15sp6o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

}

module "sles12sp5_sshminion" {
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
  additional_packages = [ "chrony" ]
}

module "sles15sp4_sshminion" {
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


module "sles15sp5_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp5"
  image              = "sles15sp5o"
  sles_registration_code = var.SLES_REGISTRATION_CODE
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

}

module "sles15sp6_sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp6"
  image              = "sles15sp6o"
  sles_registration_code = var.SLES_REGISTRATION_CODE
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  provider_settings = {
    instance_type = "t3a.medium"
  }

}

module "controller" {
  source             = "./modules/controller"
  name               = "ctl"
  provider_settings = {
    instance_type = "c6i.xlarge"
  }
  base_configuration = merge(module.base.configuration,
    {
      cc_username = var.SCC_USER
      cc_password = var.SCC_PASSWORD
    })

  product_version    = "4.3-released"
  swap_file_size = null
  no_mirror = true
  is_using_build_image      = false
  is_using_scc_repositories = false
  is_using_paygo_server     = true
  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH
  server_instance_id  =  module.server.configuration.id


  server_configuration    = module.server.configuration
  proxy_configuration     = module.proxy.configuration

  sle12sp5_paygo_minion_configuration       = module.sles12sp5_paygo_minion.configuration
  sle15sp4_byos_minion_configuration       = module.sles15sp4_byos_minion.configuration
  sle15sp5_paygo_minion_configuration       = module.sles15sp5_paygo_minion.configuration
  sle15sp6_paygo_minion_configuration       = module.sles15sp6_paygo_minion.configuration
  sleforsap15sp5_paygo_minion_configuration = module.slesforsap15sp5_paygo_minion.configuration

  sle12sp5_client_configuration    = module.sles12sp5_client.configuration
  sle12sp5_minion_configuration    = module.sles12sp5_minion.configuration
  sle12sp5_sshminion_configuration = module.sles12sp5_sshminion.configuration

  sle15sp4_client_configuration    = module.sles15sp4_client.configuration
  sle15sp4_minion_configuration    = module.sles15sp4_minion.configuration
  sle15sp4_sshminion_configuration = module.sles15sp4_sshminion.configuration

  sle15sp5_minion_configuration    = module.sles15sp5_minion.configuration
  sle15sp6_minion_configuration    = module.sles15sp6_minion.configuration
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

output "server_instance_id" {
  value = module.server.configuration.id
}
