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
  default = "eu-central-1b"
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

  images = ["rocky8", "opensuse154o", "opensuse155o", "sles15sp4o", "ubuntu2204"]

  use_avahi    = false
  name_prefix  = "uyuni-master-"
  // domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry = "mirror.sumaci.aws"
  auth_registry    = "mirror.sumaci.aws:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/cloud_aws"

  mirror = "mirror.sumaci.aws"
  // use_mirror_images = true

  // server_http_proxy = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint = "ftp://mirror.sumaci.aws:445"

  host_settings = {
    controller = {
      image = "opensuse154o"
      provider_settings = {
        instance_type = "c6i.xlarge"
        private_ip = "172.16.3.5"
        overwrite_fqdn = "uyuni-master-ctl.sumaci.aws"
      }
    }
    server = {
      provider_settings = {
        instance_type = "m6a.xlarge"
        volume_size = "100"
        private_ip = "172.16.3.6"
        overwrite_fqdn = "uyuni-master-srv.sumaci.aws"
      }
    }
    proxy = {
      provider_settings = {
        instance_type = "c6i.large"
        private_ip = "172.16.3.7"
        overwrite_fqdn = "uyuni-master-pxy.sumaci.aws"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-minion = {
      image = "opensuse155o"
      name = "min-suse"
      provider_settings = {
        instance_type = "t3a.medium"
        private_ip = "172.16.3.8"
        overwrite_fqdn = "uyuni-master-min-sles15.sumaci.aws"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = "opensuse155o"
      name = "minssh-suse"
      provider_settings = {
        instance_type = "t3a.medium"
        private_ip = "172.16.3.9"
        overwrite_fqdn = "uyuni-master-minssh-sles15.sumaci.aws"
      }
      additional_packages = [ "venv-salt-minion", "iptables" ]
      install_salt_bundle = true
    }
    redhat-minion = {
      image = "rocky8"
      provider_settings = {
        // openscap cannot run with less than 1.25 GB of RAM
        // use small instead of micro
        instance_type = "t3a.medium"
        private_ip = "172.16.3.10"
        overwrite_fqdn = "uyuni-master-min-rocky8.sumaci.aws"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    debian-minion = {
      name = "min-ubuntu2204"
      image = "ubuntu2204"
      provider_settings = {
        instance_type = "t3a.medium"
        private_ip = "172.16.3.11"
        overwrite_fqdn = "uyuni-master-min-ubuntu2204.sumaci.aws"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    build-host = {
      image = "sles15sp4o"
      provider_settings = {
        instance_type = "t3a.large"
        private_ip = "172.16.3.12"
        overwrite_fqdn = "uyuni-master-min-build.sumaci.aws"
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
// No PXE support for AWS yet
// No nested virtualization in AWS
  }
  provider_settings = {
    create_network                       = false
    vpc_id                               = "vpc-0e056f570bb1d7784"
    public_subnet_id                     = "subnet-0ddb3211d5b0feef9"
    public_security_group_id             = "sg-0a21915f3523fbede"
    create_private_network               = true
    private_network                      = "172.16.3.0/24"
    create_additional_network            = true
    additional_network                   = "172.16.4.0/24"
    bastion_host                         = "ec2-3-68-127-29.eu-central-1.compute.amazonaws.com"
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
