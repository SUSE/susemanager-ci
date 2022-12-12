
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
  default = "/home/maxime/.ssh/testing-suma.pem"
}


variable "KEY_NAME" {
  type = string
  default = "testing-suma"
}

variable "ACCESS_KEY" {
  type = string
  default = null
}

variable "SECRET_KEY" {
  type = string
  default = null
}

variable "TOKEN_AWS" {
  type = string
  default = null
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
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
//  token = var.TOKEN_AWS
}

module "base" {
  source = "./modules/base"

  cc_username              = var.SCC_USER
  cc_password              = var.SCC_PASSWORD
  name_prefix              = var.NAME_PREFIX
  mirror                   = var.MIRROR
  testsuite                = true

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
  ssh_key_path            = "./salt/controller/id_rsa.pub"

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

  //proxy_additional_repos

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
  //sle15sp4-client_additional_repos
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
  use_os_released_updates = true
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp4-minion_additional_repos

}

module "sles15sp4-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15sp4"
  image              = "sles15sp4o"
  sles_registration_code = var.SLES_REGISTRATION_CODE
  use_os_released_updates = true
  ssh_key_path            = "./salt/controller/id_rsa.pub"

}

module "rhel9-minion" {

  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-rhel9"
  image              = "rhel9"
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //ceos8-minion_additional_repos

}


module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base.configuration
  name               = "ctl"

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

  sle15sp4_client_configuration    = module.sles15sp4-client.configuration
  sle15sp4_minion_configuration    = module.sles15sp4-minion.configuration
  sle15sp4_sshminion_configuration = module.sles15sp4-sshminion.configuration

  rhel9_minion_configuration       = module.rhel9-minion.configuration

  //  redhat_configuration    = module.redhat-minion.configuration
//  debian_configuration    = module.debian-minion.configuration

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