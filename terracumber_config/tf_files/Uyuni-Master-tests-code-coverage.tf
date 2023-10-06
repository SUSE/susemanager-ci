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

terraform {
  required_version = "1.0.10"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://screwdriver.mgr.prv.suse.net/system"
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

  images = ["rocky8o", "opensuse154o", "ubuntu2204o", "sles15sp4o"]

  use_avahi    = false
  name_prefix  = "suma-codecov-"
  domain       = "mgr.prv.suse.net"
  from_email   = "root@suse.com"

  mirror      = "minima-mirror-ci-bv.mgr.prv.suse.net"
  no_auth_registry = "registry.mgr.prv.suse.net"
  auth_registry      = "registry.mgr.prv.suse.net:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_prv"

  server_http_proxy = "http-proxy.mgr.prv.suse.net:3128"
  custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.prv.suse.net:445"

  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:92:04:00:f0"
        memory = 16384
        vcpu = 6
      }
    }
    server = {
      provider_settings = {
        mac = "aa:b2:92:04:00:f1"
        memory = 65536
        vcpu = 6
      }
      server_mounted_mirror = "minima-mirror-ci-bv.mgr.prv.suse.net"
    }
    proxy = {
      provider_settings = {
        mac = "aa:b2:92:04:00:f2"
        memory = 16384
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-minion = {
      image = "opensuse154o"
      name = "min-suse"
      provider_settings = {
        mac = "aa:b2:92:04:00:f4"
        memory = 4096
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = "opensuse154o"
      name = "minssh-suse"
      provider_settings = {
        mac = "aa:b2:92:04:00:f5"
        memory = 4096
      }
      additional_packages = [ "venv-salt-minion", "iptables" ]
      install_salt_bundle = true
    }
    redhat-minion = {
      image = "rocky8o"
      name = "min-rocky8"
      provider_settings = {
        mac = "aa:b2:92:04:00:f6"
        memory = 4096
        vcpu = 2
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    debian-minion = {
      name = "min-ubuntu2204"
      image = "ubuntu2204o"
      provider_settings = {
        mac = "aa:b2:92:04:00:f7"
        memory = 4096
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = false
    }
    build-host = {
      image = "sles15sp4o"
      name = "min-build"
      provider_settings = {
        mac = "aa:b2:92:04:00:f9"
        memory = 4096
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    pxeboot-minion = {
      image = "sles15sp4o"
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    kvm-host = {
      image = "opensuse154o"
      name = "min-kvm"
      additional_grains = {
        hvm_disk_image = {
          leap = {
            hostname = "min-nested"
            image = "http://minima-mirror-ci-bv.mgr.prv.suse.net/distribution/leap/15.4/appliances/openSUSE-Leap-15.4-JeOS.x86_64-OpenStack-Cloud.qcow2"
            hash = "http://minima-mirror-ci-bv.mgr.prv.suse.net/distribution/leap/15.4/appliances/openSUSE-Leap-15.4-JeOS.x86_64-OpenStack-Cloud.qcow2.sha256"
          }
          sles = {
            hostname = "min-nested"
            image = "http://minima-mirror-ci-bv.mgr.prv.suse.net/install/SLE-15-SP4-Minimal-GM/SLES15-SP4-Minimal-VM.x86_64-OpenStack-Cloud-GM.qcow2"
            hash = "http://minima-mirror-ci-bv.mgr.prv.suse.net/install/SLE-15-SP4-Minimal-GM/SLES15-SP4-Minimal-VM.x86_64-OpenStack-Cloud-GM.qcow2.sha256"
          }
        }
      }
      provider_settings = {
        mac = "aa:b2:92:04:00:fa"
        memory = 8192
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
  }
  nested_vm_host = "min-nested"
  provider_settings = {
    pool               = "default"
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
    destination = "/etc/tomcat/conf.d/jacoco_agent.conf"
    connection {
      type     = "ssh"
      user     = "root"
      password = "linux"
      host     = "${module.cucumber_testsuite.configuration.server.hostname}"
    }
  }

  // This is just a temporary Redis instance for this PoC, no worries about it for now, but it will be good in the future to hide it as secrets in this repo
  // Only an admin of this repo will have rights to do that.
  provisioner "remote-exec" {
    inline = [ "echo export REDIS_HOST=redis-19269.c285.us-west-2-2.ec2.cloud.redislabs.com >> ~/.bashrc",
               "echo export REDIS_PORT=19269 >> ~/.bashrc",
               "echo export REDIS_USERNAME=default >> ~/.bashrc",
               "echo export REDIS_PASSWORD=I4Wxta4v5wpZGWQgUAUpnMQf35zmZGqx >> ~/.bashrc",
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
