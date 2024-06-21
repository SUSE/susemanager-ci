
// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-50/job/manager-5.0-build-image-aws"
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
  default = "Results Manager5.0-WS-MU $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Manager5.0-AWS-MU: Environment setup failed"
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

variable "SERVER_AMI" {
  type = string
  default = "slemicro55"
}

locals {
  domain            = "suma.ci.aws"
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
  images      = [ "opensuse155o"]
#   images = ["rocky8", "opensuse155o", "sles15sp5o", "sles15sp4o", "ubuntu2204"]
  provider_settings = {
    availability_zone = var.AVAILABILITY_ZONE
    region            = var.REGION
    ssh_allowed_ips   = var.ALLOWED_IPS
    key_name          = var.KEY_NAME
    key_file          = var.KEY_FILE
    route53_domain    = local.domain
    bastion_host      = "${var.NAME_PREFIX}-bastion.${local.domain}"
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
  source             = "./modules/server_containerized"
  base_configuration = merge(module.base.configuration,
  {
    mirror = null
  })
  name                       = "server"
  product_version            = "head-build_image"
  repository_disk_size       = 1500
  image                      = var.SERVER_AMI
#   server_registration_code   = var.SERVER_REGISTRATION_CODE

  runtime = "podman"
  container_repository = "registry.suse.com/suse/manager/5.0/x86_64"
  // Most recent code. Enable again once Beta 2 will be approved:
  // container_repository = "registry.suse.de/devel/galaxy/manager/head/containerfile/suse/manager/5.0/x86_64"


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
  provider_settings = {
    instance_type = "m6a.xlarge"
  }
  install_salt_bundle = false
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
  use_os_released_updates   = false
  proxy_containerized       = false
  ssh_key_path              = "./salt/controller/id_rsa.pub"
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
  //proxy_additional_repos

}

# module "proxy_containerized" {
#   source             = "./modules/proxy_containerized"
#   base_configuration = module.base_core.configuration
#   product_version    = "head"
#   name               = "pxy"
#
#   server_configuration      = module.server.configuration
#   runtime = "podman"
# #   container_repository = "registry.suse.de/suse/sle-15-sp6/update/products/manager50/containerfile/suse/manager/5.0/x86_64"
#   // Most recent code. Enable again once Beta 2 will be approved:
#   // container_repository = "registry.suse.de/devel/galaxy/manager/head/containerfile/suse/manager/5.0/x86_64"
#   auto_configure            = false
#   ssh_key_path              = "./salt/controller/id_rsa.pub"
# }

module "suse-client" {

  source             = "./modules/client"
  base_configuration = module.base.configuration
  name                 = "cli-sles15"
  image                = "sles15sp4o"
  product_version      = "4.3-released"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
  provider_settings = {
    instance_type = "t3a.medium"
  }
  //sle15sp4-client_additional_repos
}

module "suse-minion" {
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "min-sles15"
  image              = "sles15sp4o"
  server_configuration = module.server.configuration
  sles_registration_code = var.SLES_REGISTRATION_CODE
  auto_connect_to_master  = false
  use_os_released_updates = true
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
  provider_settings = {
    instance_type = "t3a.medium"
  }
  //sle15sp4-minion_additional_repos

}

module "suse-sshminion" {
  source             = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  name               = "minssh-sles15"
  image              = "sles15sp4o"
  sles_registration_code = var.SLES_REGISTRATION_CODE
  use_os_released_updates = true
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  gpg_keys                = ["default/gpg_keys/galaxy.key"]
  additional_packages = [ "venv-salt-minion" , "iptables"]
  install_salt_bundle = true
  provider_settings = {
    instance_type = "t3a.medium"
  }

}

module "debian-minion" {
  name = "min-ubuntu2204"
  image = "ubuntu2204"
  source             = "./modules/minion"
  base_configuration = module.base.configuration
  product_version    = "4.3-released"
  server_configuration = module.server.configuration
  auto_connect_to_master  = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
  additional_packages = [ "venv-salt-minion" ]
  install_salt_bundle = true
  provider_settings = {
    instance_type = "t3a.medium"
  }
}

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

module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base.configuration
  name               = "ctl"
  provider_settings = {
    memory             = 16384
    vcpu               = 8
  }
  swap_file_size = null
  no_mirror = true
  is_using_build_image = true
  is_using_scc_repositories = true
  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration    = module.server.configuration
  proxy_configuration     = module.proxy.configuration
  client_configuration    = module.suse-client.configuration
  minion_configuration    = module.suse-minion.configuration
//  buildhost_configuration = module.build-host.configuration
  sshminion_configuration = module.suse-sshminion.configuration
#   redhat_configuration    = module.redhat-minion.configuration
  debian_configuration    = module.debian-minion.configuration

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
