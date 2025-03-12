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

variable "PROMETHEUS_PUSH_GATEWAY_URL" {
  type = string
  default = null
}

terraform {
  required_version = "1.0.10"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.8.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://suma-03.mgr.suse.de/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "head"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username   = var.SCC_USER
  cc_password   = var.SCC_PASSWORD

  images = ["rocky8o", "opensuse155o", "opensuse156o", "ubuntu2404o", "sles15sp4o", "slmicro61o", "slemicro55o"]

  use_avahi     = false
  name_prefix   = "suma-test-hexagon-"
  domain        = "mgr.suse.de"
  from_email    = "root@suse.de"

  no_auth_registry          = "registry.mgr.suse.de"
  auth_registry             = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username    = "cucutest"
  auth_registry_password    = "cucusecret"
  git_profiles_repo         = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  container_server          = true
  container_proxy           = true

  mirror                    = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images         = true
  server_http_proxy         = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint  = "ftp://minima-mirror-ci-bv.mgr.suse.de:445"

  host_settings = {
    controller = {
      provider_settings = {
        mac     = "aa:b2:93:01:00:50"
        vcpu    = 2
        memory  = 2048
      }
    }
    server_containerized = {
      provider_settings     = {
        mac     = "aa:b2:93:01:00:51"
        vcpu    = 4
        memory  = 16384
      }
      runtime = "podman"
      container_repository = "registry.suse.de/devel/galaxy/manager/test/hexagon/containerfile/multi-linux-manager/5.1/x86_64"
      container_tag = "latest"
      additional_repos = {
        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Hexagon/SLE_15_SP7/"
      }
      main_disk_size        = 80
      repository_disk_size  = 200
      database_disk_size    = 30
      login_timeout         = 28800
      large_deployment      = true
    }
    proxy_containerized = {
      provider_settings = {
        mac     = "aa:b2:93:01:00:52"
        vcpu    = 2
        memory  = 2048
      }
      runtime = "podman"
      container_repository = "registry.suse.de/devel/galaxy/manager/test/hexagon/containerfile/multi-linux-manager/5.1/x86_64"
      container_tag = "latest"
      additional_repos = {
        Test_repo = "http://download.suse.de/ibs/Devel:/Galaxy:/Manager:/TEST:/Hexagon/SLE_15_SP7
      }
    }
    suse_minion = {
      image = "sles15sp4o"
      provider_settings = {
        mac     = "aa:b2:93:01:00:56"
        vcpu    = 2
        memory  = 2048
      }
    }
    suse_sshminion = {
      image = "sles15sp4o"
      provider_settings = {
        mac     = "aa:b2:93:01:00:58"
        vcpu    = 2
        memory  = 2048
      }
      additional_packages = [ "iptables" ]
    }
    rhlike_minion = {
      image             = "rocky8o"
      provider_settings = {
        mac     = "aa:b2:93:01:00:5a"
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Also, openscap cannot run with less than 1.25 GB of RAM
        vcpu    = 2
        memory  = 2048
      }
    }
    build_host = {
      image             = "sles15sp4o"
      provider_settings = {
        mac     = "aa:b2:93:01:00:5d"
        vcpu    = 2
        memory  = 2048
      }
    }
    pxeboot_minion = {
      image  = "sles15sp4o"
    }
    dhcp_dns = {
      name = "dhcp-dns"
      image = "opensuse155o"
      hypervisor = {
        host        = "suma-03.mgr.suse.de"
        user        = "root"
        private_key = file("~/.ssh/id_ed25519")
      }
    }
  }
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br0"
  }
}


resource "null_resource" "configure_quality_intelligence" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {
    inline = [ "echo export QUALITY_INTELLIGENCE=true >> ~/.bashrc",
      "echo export PROMETHEUS_PUSH_GATEWAY_URL=${var.PROMETHEUS_PUSH_GATEWAY_URL} >> ~/.bashrc",
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
