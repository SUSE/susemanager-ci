
// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-manager-mu-cloud"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = "string"
  default = "export PRODUCT='Uyuni' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = "string"
  default = "https://github.com/uyuni-project/uyuni.git"
}

variable "CUCUMBER_BRANCH" {
  type = "string"
  default = "master"
}

variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results Uyuni-Master $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results Uyuni-Master: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = "string"
  default = "mnoel@suse.de"
}

variable "MAIL_TO" {
  type = "string"
  default = "mnoel@suse.de"
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

variable "REGION" {
  type = "string"
  default = "eu-central-1"
}

variable "AVAILABILITY_ZONE" {
  type = "string"
  default = "eu-central-1a"
}

variable "KEY_FILE" {
  type = "string"
  default = "/home/jenkins/.ssh/testing-suma.pem"
}

variable "KEY_NAME" {
  type = "string"
  default = "testing-suma"
}

variable "ACCESS_KEY" {
  type = "string"
  default = null
}

variable "SECRET_KEY" {
  type = "string"
  default = null
}

provider "aws" {
  region     = var.REGION
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
}

module "base" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix  = "uyuni-mu-aws-"
  //  mirror = "ip-172-16-1-50.eu-central-1.compute.internal"
  provider_settings = {
    availability_zone = var.AVAILABILITY_ZONE
    region            = var.REGION
    ssh_allowed_ips   = ["202.180.93.210", "65.132.116.252"]
    key_name          = var.KEY_NAME
    key_file          = var.KEY_FILE
  }
}


module "mirror" {
  source = "./modules/mirror"
  base_configuration = module.base.configuration
  provider_settings = {
    public_instance = true
  }
  volume_provider_settings = {
    # uncomment the following line if you want to reuse an data disk snapshot
    //    volume_snapshot_id = data.aws_ebs_snapshot.data_disk_snapshot.id
  }
}


output "bastion_public_name" {
  value = lookup(module.base.configuration, "bastion_host", null)
}
//
//output "aws_server_mirrors_private_name" {
//  value = module.mirror.configuration["hostnames"][0]
//}
//
//output "aws_server_mirrors_public_name" {
//  value = module.mirror.configuration["public_names"][0]
//}

//
//output "mirror_hosts" {
//  value = lookup(module.base.configuration, "mirror", null)
//}
//output "aws_server_private_name" {
//  value = module.server.configuration.hostname
//}
//
//output "aws_minion_private_names" {
//  value = module.minion.configuration.hostnames
//}
