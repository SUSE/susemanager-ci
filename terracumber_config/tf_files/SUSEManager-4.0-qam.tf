// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Manager-4.0/job/manager-4.0-qam-setup-cucumber"
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
  default = "Manager-4.0"
}

variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results 4.0 QAM $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results 4.0 QAM: Environment setup failed"
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
  name_prefix = "qam-pip-40-"
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
  name_prefix = "qam-pip-40-"
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
  name_prefix = "qam-pip-40-"
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
  product_version    = "4.0-released"
  name               = "srv"
  provider_settings = {
    mac                = "52:54:00:F6:5D:E8"
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
  product_version    = "4.0-released"
  name               = "pxy"
  provider_settings = {
    mac                = "52:54:00:F2:4D:7A"
    memory             = 4096
  }
  server_configuration = {
    hostname = "qam-pip-40-srv.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "cli-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "52:54:00:0E:F8:ED"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "cli-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "52:54:00:66:70:7B"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "cli-sles15"
  image              = "sles15o"
  provider_settings = {
    mac                = "52:54:00:06:F2:85"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "cli-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "52:54:00:BA:1D:11"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "cli-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "52:54:00:72:41:8A"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "cli-centos6"
  image              = "centos6o"
  provider_settings = {
    mac                = "52:54:00:BA:ED:61"
    memory             = 2048
  }
  use_os_released_updates = false
  server_configuration =  { hostname = "qam-pip-40-pxy.qa.prv.suse.net" }
  ssh_key_path = "./salt/controller/id_rsa.pub"
}

module "sles12sp4-minion" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/minion"
  base_configuration = module.base2.configuration
  product_version    = "4.0-released"
  name               = "min-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "52:54:00:B2:49:5C"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "min-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "52:54:00:02:C8:20"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "min-sles15"
  image              = "sles15o"
  provider_settings = {
    mac                = "52:54:00:DA:C7:79"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "min-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "52:54:00:72:E5:BE"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "min-centos8"
  image              = "centos8o"
  provider_settings = {
    mac                = "52:54:00:99:CF:C8"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "min-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "52:54:00:92:F9:D6"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "min-centos6"
  image              = "centos6o"
  provider_settings = {
    mac                = "52:54:00:7A:13:48"
    memory             = 2048
  }
  server_configuration =  { hostname = "qam-pip-40-pxy.qa.prv.suse.net" }
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
  product_version    = "4.0-released"
  name               = "min-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "52:54:00:2A:47:D8"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "min-ubuntu1804"
  image              = "ubuntu1804o"
  provider_settings = {
    mac                = "52:54:00:D2:5E:EC"
    memory             = 2048
  }
  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
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
  product_version    = "4.0-released"
  name               = "min-ubuntu1604"
  image              = "ubuntu1604o"
  provider_settings = {
    mac                = "52:54:00:12:33:D8"
    memory             = 2048
  }
  server_configuration =  { hostname =  "qam-pip-40-pxy.qa.prv.suse.net" }
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
  product_version    = "4.0-released"
  name               = "minssh-sles12sp4"
  image              = "sles12sp4o"
  provider_settings = {
    mac                = "52:54:00:DA:AD:B0"
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
  product_version    = "4.0-released"
  name               = "minssh-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "52:54:00:3A:0D:F9"
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
  product_version    = "4.0-released"
  name               = "minssh-sles15"
  image              = "sles15o"
  provider_settings = {
    mac                = "52:54:00:62:D7:5D"
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
  product_version    = "4.0-released"
  name               = "minssh-sles15sp1"
  image              = "sles15sp1o"
  provider_settings = {
    mac                = "52:54:00:26:7C:DE"
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
  product_version    = "4.0-released"
  name               = "minssh-centos8"
  image              = "centos8o"
  provider_settings = {
    mac                = "52:54:00:AE:F1:6C"
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
  product_version    = "4.0-released"
  name               = "minssh-centos7"
  image              = "centos7o"
  provider_settings = {
    mac                = "52:54:00:EA:AA:42"
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
  product_version    = "4.0-released"
  name               = "minssh-centos6"
  image              = "centos6o"
  provider_settings = {
    mac                = "52:54:00:96:6B:AC"
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
  product_version    = "4.0-released"
  name               = "minssh-ubuntu2004"
  image              = "ubuntu2004o"
  provider_settings = {
    mac                = "52:54:00:2A:47:D8"
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
  product_version    = "4.0-released"
  name               = "minssh-ubuntu1804"
  image              = "ubuntu1804o"
  provider_settings = {
    mac                = "52:54:00:8E:00:5A"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path       = "./salt/controller/id_rsa.pub"
}

module "ubuntu1604-sshminion" {
  source = "./modules/sshminion"
  base_configuration = module.base.configuration
  product_version    = "4.0-released"
  name               = "minssh-ubuntu1604"
  image              = "ubuntu1604o"
  provider_settings = {
    mac                = "52:54:00:CE:FE:C8"
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
    mac                = "52:54:00:B2:CF:9B"
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
