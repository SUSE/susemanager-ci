// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = string
  default = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-master-dev-acceptance-tests-RKE2"
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
  default = "Results Uyuni-Master RKE2 $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = string
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = string
  default = "Results Uyuni-Master RKE2: Environment setup failed"
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
  required_version = ">= 1.6.0"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu+tcp://https://moscowmule.mgr.slc1.suse.org//system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "uyuni-master"

  // Kubernetes variables
  kubernetes                     = true
  use_devel_oci                  = true
  install_mlm_server             = true
  install_mlm_proxy              = true
  install_traefik                = true
  install_local_path_provisioner = true
  deploy_coco_attestation        = true
  deploy_saline                  = true
  deploy_tftp                    = true
  install_kubectl_helm           = false
  kubeconfig_path                = null

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["tumbleweedo", "opensuse156o"]

  use_avahi    = false
  name_prefix  = "uyuni-ci-master-benchmark-rke2-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry = "registry.mgr.suse.de"
  auth_registry      = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/temporary"
  
  container_server = true
  container_proxy  = true

  mirror                   = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images        = true

  # server_http_proxy = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.suse.de:445"

  # when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:93:01:00:10"
      }
    }
  }
  
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br0"
    additional_network = "192.168.101.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
