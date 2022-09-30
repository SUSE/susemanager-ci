// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-master-dev-acceptance-tests-AWS"
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
  default = "Results Uyuni-Master AWS: $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Uyuni-Master AWS: Environment setup failed"
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

variable "REGION" {
  type = string
  default = "eu-central-1"
}

variable "AVAILABILITY_ZONE" {
  type = string
  default = "eu-central-1a"
}

variable "KEY_FILE" {
  type = string
  default = "/home/jenkins/.ssh/id_rsa"
}

variable "KEY_NAME" {
  type = string
  default = "internal-jenkins-worker"
}

variable "MY_IP" {
  type = string
  default = ""
}

provider "aws" {
  region     = var.REGION
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

  images = ["rocky8o", "opensuse153o", "opensuse154o", "sles15sp2o", "sles15sp3o", "ubuntu2204"]

  use_avahi    = false
  name_prefix  = "uyuni-master-"
  // domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry = "ip-172-16-1-30.eu-central-1.compute.internal"
  auth_registry    = "ip-172-16-1-30.eu-central-1.compute.internal:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#testing_in_aws:testsuite/features/profiles/cloud_aws"

  mirror = "ip-172-16-1-30.eu-central-1.compute.internal"
  // use_mirror_images = true

  // server_http_proxy = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint = "ftp://ip-172-16-1-30.eu-central-1.compute.internal:445"

  host_settings = {
    controller = {
      image = "opensuse154o"
    }
    server = {
      provider_settings = {
      }
    }
    proxy = {
      provider_settings = {
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-minion = {
      image = "sles15sp4o"
      name = "min-sles15"
      provider_settings = {
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = "sles15sp4o"
      name = "minssh-sles15"
      provider_settings = {
      }
      additional_packages = [ "venv-salt-minion", "iptables" ]
      install_salt_bundle = true
    }
    redhat-minion = {
      image = "rocky8o"
      provider_settings = {
        // openscap cannot run with less than 1.25 GB of RAM
        // use small instead of micro
        // t3 has problems with network interfaces setup
        instance_type = "t2.small"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    debian-minion = {
      name = "min-ubuntu2204"
      image = "ubuntu2204"
      provider_settings = {
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    build-host = {
      image = "sles15sp4o"
      provider_settings = {
        // 2 GB RAM needed - use small instead of micro
        instance_type = "t3.small"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
// No PXE support for AWS yet
//    pxeboot-minion = {
//       image = "opensuse153o"
//      provider_settings = {
//      }
//    }
// We need to clarify if this is supported at AWS
//    kvm-host = {
//      image = "opensuse153o"
//      provider_settings = {
//      }
//    }
//    xen-host = {
//      image = "opensuse153o"
//      provider_settings = {
//      }
//    }
  }
  provider_settings = {
    create_network                       = false
    public_subnet_id                     = "subnet-01db332a7f8bd5ba1"
    private_subnet_id                    = "subnet-00a0b59c64ca94e3c"
    private_additional_subnet_id         = "subnet-07d1f93fe7cea5b33"
    public_security_group_id             = "sg-0b8c5f685bf50ca0d"
    private_security_group_id            = "sg-00dffcc61093a3630"
    private_additional_security_group_id = "sg-0aaa32fdc02bb7e73"
    bastion_host                         = "ec2-3-73-148-21.eu-central-1.compute.amazonaws.com"
    availability_zone                    = var.AVAILABILITY_ZONE
    region                               = var.REGION
    ssh_allowed_ips                      = []
    key_name                             = var.KEY_NAME
    key_file                             = var.KEY_FILE
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
