// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Manager-4.1/job/manager-4.1-qam-setup-cucumber"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = "string"
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = "string"
  default = "https://github.com/SUSE/spacewalk.git"
}

variable "CUCUMBER_BRANCH" {
  type = "string"
  default = "Manager-4.1"
}

variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results 4.1 QAM $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results 4.1 QAM: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = "string"
  default = "galaxy-ci@suse.de"
}

variable "MAIL_TO" {
  type = "string"
  default = "galaxy-ci@suse.de"
}

// sumaform specific variables
variable "SCC_USER" {
  type = "string"
}

variable "SCC_PASSWORD" {
  type = "string"
}

variable "GIT_USER" {
  type = "string"
  default = null // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type = "string"
  default = null // Not needed for master, as it is public
}

provider "libvirt" {
  uri = "qemu+tcp://classic176.qa.prv.suse.net/system"
}

provider "libvirt" {
  alias = "classic179"
  uri = "qemu+tcp://classic179.qa.prv.suse.net/system"
}

provider "libvirt" {
  alias = "classic181"
  uri = "qemu+tcp://classic181.qa.prv.suse.net/system"
}


module "base" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "qam-pip-41-"
  use_avahi   = false
  domain      = "qa.prv.suse.net"
  images      = [ "sles15o", "sles15sp1o", "opensuse150o" ]

  mirror = "minima-mirror.qa.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "default"
    bridge      = "br0"
    additional_network = "192.168.40.0/24"
  }
}

module "base2" {
  providers = {
    libvirt = libvirt.classic179
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "qam-pip-41-"
  use_avahi   = false
  domain      = "qa.prv.suse.net"
  images      = [ "sles11sp4", "sles12sp4o", "sles15o", "sles15sp1o", "centos6o", "centos7o" ]

  mirror = "minima-mirror.qa.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "default"
    bridge      = "br0"
    additional_network = "192.168.40.0/24"
  }
}

module "base3" {
  providers = {
    libvirt = libvirt.classic181
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "qam-pip-41-"
  use_avahi   = false
  domain      = "qa.prv.suse.net"
  images      = [ "sles15sp1o",  "ubuntu1804o", "ubuntu1604o", "ubuntu2004o", "centos8o" ]

  mirror = "minima-mirror.qa.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "default"
    bridge      = "br0"
    additional_network = "192.168.40.0/24"
  }
}


module "server" {
  source             = "./modules/server"
  base_configuration = module.base.configuration
  product_version    = "4.1-released"
  name               = "srv"
  provider_settings = {
    mac                = "52:54:00:46:86:8A"
    memory             = 40960
    vcpu               = 6
    data_pool            = "default"
  }

  repository_disk_size = 750

  auto_accept                    = false
  monitored                      = true
  disable_firewall               = false
  allow_postgres_connections     = false
  skip_changelog_import          = false
  browser_side_less              = false
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

  //srv_additional_repos

}

module "proxy" {
  source             = "./modules/proxy"
  base_configuration = module.base.configuration
  product_version    = "4.1-released"
  name               = "pxy"
  provider_settings = {
    mac                = "52:54:00:FA:0A:A5"
    memory             = 4096
  }
  server_configuration = {
    hostname = "qam-pip-41-srv.qa.prv.suse.net"
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

}

module "sles12sp4-client" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/client"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "cli-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "52:54:00:DE:8B:4B"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles11sp4-client" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/client"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "cli-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "52:54:00:CE:B2:F6"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15-client" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/client"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "cli-sles15"
  image              = "sles15o"
  provider_settings = {
    mac                = "52:54:00:56:49:43"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp1-client" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/client"
  base_configuration = module.base3.configuration
  product_version    = "4.1-released"
  name               = "cli-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "52:54:00:7A:84:9E"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "centos7-client" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/client"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "cli-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "52:54:00:8E:E6:5B"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_register = false
  use_os_released_updates = false
  ssh_key_path  = "./salt/controller/id_rsa.pub"
}

module "centos6-client" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/client"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "cli-centos6"
  image              = "centos6o"
  provider_settings = {
    mac                = "52:54:00:EE:2D:80"
    memory             = 2048
  }
  use_os_released_updates = false
  server_configuration =  { hostname = "qam-pip-41-pxy.qa.prv.suse.net" }
  ssh_key_path = "./salt/controller/id_rsa.pub"
}

module "sles12sp4-minion" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/minion"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "min-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "52:54:00:9A:94:C9"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles11sp4-minion" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/minion"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "min-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "52:54:00:6A:52:82"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15-minion" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/minion"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "min-sles15"
  image              = "sles15o"
  provider_settings = {
    mac                = "52:54:00:82:63:59"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp1-minion" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/minion"
  base_configuration = module.base3.configuration
  product_version    = "4.1-released"
  name               = "min-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "52:54:00:CA:F7:A9"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "centos8-minion" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/minion"
  base_configuration = module.base3.configuration
  product_version    = "4.1-released"
  name               = "min-centos8"
  image              = "centos8o"
  provider_settings = {
    mac                = "52:54:00:11:EA:1D"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master = false
  use_os_released_updates = false
  ssh_key_path           = "./salt/controller/id_rsa.pub"
}

module "centos7-minion" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/minion"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "min-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "52:54:00:56:1E:C9"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master = false
  use_os_released_updates = false
  ssh_key_path           = "./salt/controller/id_rsa.pub"
}

module "centos6-minion" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/minion"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "min-centos6"
  image              = "centos6o"
  provider_settings = {
    mac                = "52:54:00:76:EF:77"
    memory             = 2048
  }
  server_configuration =  { hostname = "qam-pip-41-pxy.qa.prv.suse.net" }
  auto_connect_to_master = false
  use_os_released_updates = false
  ssh_key_path = "./salt/controller/id_rsa.pub"
}

module "ubuntu2004-minion" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/minion"
  base_configuration = module.base3.configuration
  product_version    = "4.1-released"
  name               = "min-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "52:54:00:15:A7:50"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master = false
  use_os_released_updates = false
  ssh_key_path           = "./salt/controller/id_rsa.pub"
}

module "ubuntu1804-minion" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/minion"
  base_configuration = module.base3.configuration
  product_version    = "4.1-released"
  name               = "min-ubuntu1804"
  image              = "ubuntu1804o"
  provider_settings = {
    mac                = "52:54:00:7E:7D:ED"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-41-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master = false
  use_os_released_updates = false
  ssh_key_path           = "./salt/controller/id_rsa.pub"
}

module "ubuntu1604-minion" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/minion"
  base_configuration = module.base3.configuration
  product_version    = "4.1-released"
  name               = "min-ubuntu1604"
  image              = "ubuntu1604o"
  provider_settings = {
    mac                = "52:54:00:DA:F0:A0"
    memory             = 2048
  }
  server_configuration =  { hostname =  "qam-pip-41-pxy.qa.prv.suse.net" }
  auto_connect_to_master = false
  use_os_released_updates = false
  ssh_key_path = "./salt/controller/id_rsa.pub"
}

module "sles12sp4-sshminion" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/sshminion"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "minssh-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "52:54:00:9A:51:7B"
    memory             = 2048
  }

  use_os_released_updates = false
  ssh_key_path = "./salt/controller/id_rsa.pub"
  gpg_keys     = ["default/gpg_keys/galaxy.key"]
}

module "sles11sp4-sshminion" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/sshminion"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "minssh-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "52:54:00:56:0F:F7"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15-sshminion" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/sshminion"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "minssh-sles15"
  image              = "sles15o"
  provider_settings = {
    mac                = "52:54:00:8A:F9:39"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "sles15sp1-sshminion" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/sshminion"
  base_configuration = module.base3.configuration
  product_version    = "4.1-released"
  name               = "minssh-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "52:54:00:EE:AD:30"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "centos8-sshminion" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/sshminion"
  base_configuration = module.base3.configuration
  product_version    = "4.1-released"
  name               = "minssh-centos8"
  image              = "centos8o"
  provider_settings = {
    mac                = "52:54:00:05:67:B3"
    memory             = 2048
  use_os_released_updates = false
  ssh_key_path = "./salt/controller/id_rsa.pub"
}

module "centos7-sshminion" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/sshminion"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "minssh-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "52:54:00:32:A9:28"
    memory             = 2048
  use_os_released_updates = false
  ssh_key_path = "./salt/controller/id_rsa.pub"
}

module "centos6-sshminion" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/sshminion"
  base_configuration = module.base2.configuration
  product_version    = "4.1-released"
  name               = "minssh-centos6"
  image              = "centos6o"
  provider_settings = {
    mac                = "52:54:00:D6:E1:67"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path = "./salt/controller/id_rsa.pub"
}

module "ubuntu2004-sshminion" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/sshminion"
  base_configuration = module.base3.configuration
  product_version    = "4.1-released"
  name               = "minssh-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "52:54:00:E9:7F:D7"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path       = "./salt/controller/id_rsa.pub"
}

module "ubuntu1804-sshminion" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/sshminion"
  base_configuration = module.base3.configuration
  product_version    = "4.1-released"
  name               = "minssh-ubuntu1804"
  image              = "ubuntu1804o"
  provider_settings = {
    mac                = "52:54:00:EE:EC:95"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path       = "./salt/controller/id_rsa.pub"
}

module "ubuntu1604-sshminion" {
  source = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.1-released"
  name               = "minssh-ubuntu1604"
  image              = "ubuntu1604o"
  provider_settings = {
    mac                = "52:54:00:96:3B:E1"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path = "./salt/controller/id_rsa.pub"
}


module "controller" {
  source             = "./modules/controller"
  base_configuration = module.base.configuration
  name               = "ctl"
  provider_settings = {
    mac                = "52:54:00:BA:9D:AD"
    memory             = 16384
    vcpu               = 6
  }

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration = module.server.configuration
  proxy_configuration  = module.proxy.configuration

  centos6_client_configuration = module.centos6-client.configuration
  centos6_minion_configuration = module.centos6-minion.configuration
  centos6_sshminion_configuration = module.centos6-sshminion.configuration

  centos7_client_configuration    = module.centos7-client.configuration
  centos7_minion_configuration    = module.centos7-minion.configuration
  centos7_sshminion_configuration = module.centos7-sshminion.configuration

  centos8_minion_configuration    = module.centos8-minion.configuration
  centos8_sshminion_configuration = module.centos8-sshminion.configuration

  sle11sp4_client_configuration    = module.sles11sp4-client.configuration
  sle11sp4_minion_configuration    = module.sles11sp4-minion.configuration
  sle11sp4_sshminion_configuration = module.sles11sp4-sshminion.configuration

  sle12sp4_client_configuration    = module.sles12sp4-client.configuration
  sle12sp4_minion_configuration    = module.sles12sp4-minion.configuration
  sle12sp4_sshminion_configuration = module.sles12sp4-sshminion.configuration

  client_configuration    = module.sles12sp4-client.configuration
  minion_configuration    = module.sles12sp4-minion.configuration
  sshminion_configuration = module.sles12sp4-sshminion.configuration

  sle15_client_configuration    = module.sles15-client.configuration
  sle15_minion_configuration    = module.sles15-minion.configuration
  sle15_sshminion_configuration = module.sles15-sshminion.configuration

  sle15sp1_client_configuration    = module.sles15sp1-client.configuration
  sle15sp1_minion_configuration    = module.sles15sp1-minion.configuration
  sle15sp1_sshminion_configuration = module.sles15sp1-sshminion.configuration

  ubuntu1604_minion_configuration = module.ubuntu1604-minion.configuration
  ubuntu1604_sshminion_configuration = module.ubuntu1604-sshminion.configuration

  ubuntu1804_minion_configuration = module.ubuntu1804-minion.configuration
  ubuntu1804_sshminion_configuration = module.ubuntu1804-sshminion.configuration

  ubuntu2004_minion_configuration = module.ubuntu2004-minion.configuration
  ubuntu2004_sshminion_configuration = module.ubuntu2004-sshminion.configuration
}

output "configuration" {
  value = {
    controller = module.controller.configuration
  }
}
