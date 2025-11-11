// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-master-dev-acceptance-tests-code-coverage"
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
  default = "Results Uyuni-Master-test-code-coverage $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Uyuni-Master Code Coverage: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = string
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = string
  default = "jenkins@suse.de"
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

variable "REDIS_HOST" {
  type = string
  default = null
}

variable "REDIS_USERNAME" {
  type = string
  default = null
}

variable "REDIS_PASSWORD" {
  type = string
  default = null
}

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://screwdriver.mgr.slc1.suse.org/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "uyuni-master"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["rocky8o", "opensuse155o", "opensuse156o", "leapmicro55o", "ubuntu2404o", "sles15sp4o", "tumbleweedo"]

  use_avahi    = false
  name_prefix  = "suma-codecov-"
  domain       = "mgr.slc1.suse.org"
  from_email   = "root@suse.com"

  container_server = true
  container_proxy  = true

  // mirror                   = "minima-mirror-ci-bv.mgr.slc1.suse.org"
  // use_mirror_images        = true
  
  no_auth_registry = "registry.mgr.slc1.suse.org"
  auth_registry      = "registry.mgr.slc1.suse.org:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_slc"

  # server_http_proxy = "http-proxy.mgr.slc1.suse.org:3128"
  custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.slc1.suse.org:445"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:92:04:00:f0"
        memory = 16384
        vcpu = 6
      }
    }
    server_containerized = {
      provider_settings = {
        mac = "aa:b2:92:04:00:f1"
        memory = 65536
        vcpu = 6
      }
      runtime               = "podman"
      container_repository  = "registry.opensuse.org/systemsmanagement/uyuni/master/containerfile"
      container_tag         = "latest"
      helm_chart_url        = "oci://registry.opensuse.org/systemsmanagement/uyuni/master/charts/uyuni/server"
      main_disk_size        = 40
      repository_disk_size  = 250
      database_disk_size    = 60
      login_timeout         = 28800
      large_deployment      = true
    }
    proxy_containerized = {
      provider_settings = {
        mac = "aa:b2:92:04:00:f2"
        memory = 16384
      }
      runtime               = "podman"
      container_repository  = "registry.opensuse.org/systemsmanagement/uyuni/master/containerfile"
      container_tag         = "latest"
    }
    suse_minion = {
      image = "tumbleweedo"
      provider_settings = {
        mac = "aa:b2:92:04:00:f4"
        memory = 4096
      }
    }
    suse_sshminion = {
      image = "tumbleweedo"
      provider_settings = {
        mac = "aa:b2:92:04:00:f5"
        memory = 4096
      }
    }
    rhlike_minion = {
      image = "rocky8o"
      provider_settings = {
        mac = "aa:b2:92:04:00:f6"
        memory = 4096
        vcpu = 2
      }
    }
    // deblike_minion = {
    //   image = "ubuntu2404o"
    //   provider_settings = {
    //     mac = "aa:b2:92:04:00:f7"
    //     memory = 4096
    //   }
    // }
    build_host = {
     image = "sles15sp4o"
     provider_settings = {
       mac = "aa:b2:92:04:00:f9"
       memory = 4096
     }
    }
    pxeboot_minion = {
     image = "sles15sp4o"
    }
    dhcp_dns = {
      name = "dhcp-dns"
      image = "opensuse155o"
      hypervisor = {
        host        = "screwdriver.mgr.slc1.suse.org"
        user        = "root"
        private_key = file("~/.ssh/id_ed25519")
      }
    }
  }
  
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br1"
    additional_network = "192.168.112.0/24"
  }
}

resource "null_resource" "configure_jacoco" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "file" {
    source      = "../../susemanager-ci/terracumber_config/config_files/jacoco_agent.conf"
    destination = "/var/lib/containers/storage/volumes/etc-tomcat/_data/conf.d/jacoco_agent.conf"
    connection {
      type     = "ssh"
      user     = "root"
      password = "linux"
      host     = "${module.cucumber_testsuite.configuration.server.hostname}"
    }
  }

  provisioner "remote-exec" {
    inline = [ "echo export CODE_COVERAGE=true >> ~/.bashrc",
               "echo export REDIS_HOST=${var.REDIS_HOST} >> ~/.bashrc",
               "echo export REDIS_PORT=6379 >> ~/.bashrc",
               "echo export REDIS_USERNAME=${var.REDIS_USERNAME} >> ~/.bashrc",
               "echo export REDIS_PASSWORD=${var.REDIS_PASSWORD} >> ~/.bashrc",
               "source ~/.bashrc"
             ]
    connection {
      type     = "ssh"
      user     = "root"
      password = "linux"
      host     = "${module.cucumber_testsuite.configuration.controller.hostname}"
    }
  }

}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
