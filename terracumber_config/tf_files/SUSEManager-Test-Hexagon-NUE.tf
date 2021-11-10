// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Manager-Test/job/manager-TEST-Hexagon-acceptance-tests"
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
  default = "Results TEST-HEXAGON $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results TEST-HEXAGON: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = string
  default = "galaxy-ci@suse.de"
}

variable "MAIL_TO" {
  type = string
  default = "galaxy-ci@suse.de"
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

provider "libvirt" {
  uri = "qemu+tcp://cthulu.mgr.suse.de/system"
}

module "base_core" {
  source = "./modules/base"

  
  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["centos7o", "opensuse150o", "opensuse151o", "opensuse152o", "sles15sp1o", "sles15sp2o", "ubuntu1804o", "sles12sp4o", "sles11sp4"]

  use_avahi    = false
  name_prefix  = "suma-testhexagon-"
  domain       = "mgr.suse.de"

  provider_settings = {
    pool         = "ssd"
    network_name = null
    bridge       = "br0"
  }
}

module "server" {
  source             = "./modules/server"
  base_configuration = module.base_core.configuration
  product_version = "uyuni-master"
  name               = "srv"
  provider_settings = {
    mac = "aa:b2:93:01:00:51"
  }
  additional_repos = {
      Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Hexagon/openSUSE_Leap_15.3/"
  }

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
  ssh_key_path                   = "./salt/controller/id_rsa.pub"
  from_email                     = "root@suse.de"

  //server_additional_repos
}

module "proxy" {
  source             = "./modules/proxy"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  name               = "pxy"
  provider_settings = {
    mac = "aa:b2:93:01:00:52"
  }
  server_configuration = {
    hostname = "suma-testhexagon-pxy.mgr.suse.de"
    username = "admin"
    password = "admin"
  }
  auto_register             = false
  auto_connect_to_master    = false
  download_private_ssl_key  = false
  auto_configure            = false
  generate_bootstrap_script = false
  publish_private_ssl_key   = false
  use_os_released_updates   = true
  ssh_key_path              = "./salt/controller/id_rsa.pub"

  //proxy_additional_repos
  additional_repos = {
    Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Hexagon/openSUSE_Leap_15.3/"
  }
}

module "sles12sp4-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  //name               = "min-sles12sp4"
  name               = "min-sles12"
  image              = "sles12sp4o"
  provider_settings = {
    mac = "aa:b2:93:01:00:55"
  }
  server_configuration = {
    hostname = "suma-testhexagon-min-sles12.mgr.suse.de"
  }

  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle12sp4-client_additional_repos
  additional_repos = {
    Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Hexagon/CLIENT-SLE_12/"
  }
}

module "sles11sp4-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  //name               = "cli-sles11sp4"
  name               = "min-build"
  image              = "sles11sp4"
  provider_settings = {
    mac = "aa:b2:93:01:00:5d"
  }
  server_configuration = {
    hostname = "suma-testhexagon-min-build.mgr.suse.de"
  }

  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle11sp4-client_additional_repos
  additional_repos = {
    Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Hexagon/CLIENT-SLE_11/"
  }
}

module "sles15sp2-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  //name               = "cli-sles15sp2"
  name               = "cli-sles15"
  image              = "sles15sp2o"
  provider_settings = {
    mac = "aa:b2:93:01:00:54"
  }
  server_configuration = {
    hostname = "suma-testhexagon-cli-sles15.mgr.suse.de"
  }

  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"

  //sle15sp2-client_additional_repos
  additional_repos = {
    Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Hexagon/SLE_15_SP2/"
  }
}

module "centos7-client" {
  source             = "./modules/client"
  base_configuration = module.base_core.configuration
  product_version    = "uyuni-master"
  //name               = "cli-centos7"
  name               = "min-centos7"
  image              = "centos7o"
  provider_settings = {
    mac = "aa:b2:93:01:00:59"
  }
  server_configuration = {
    hostname = "suma-testhexagon-min-centos7.mgr.suse.de"
  }

  auto_register = false
  use_os_released_updates = false
  ssh_key_path  = "./salt/controller/id_rsa.pub"

  //ceos7-client_additional_repos
  additional_repos = {
    Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Hexagon/CLIENT-RES7/"
  }
}

module "controller" { 
  source             = "./modules/controller"
  base_configuration = module.base_core.configuration
  name               = "ctl"
  provider_settings = {
    mac = "aa:b2:93:01:00:50"
  }
  swap_file_size = 2048

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH
  
  server_configuration = module.server.configuration
  proxy_configuration  = module.proxy.configuration

  sle11sp4_client_configuration    = module.sles11sp4-client.configuration
  sle12sp4_client_configuration    = module.sles12sp4-client.configuration
  client_configuration             = module.sles15sp2-client.configuration
  centos7_client_configuration    = module.centos7-client.configuration
}

output "configuration" {
  value = {
    controller = module.controller.configuration
  }
}
