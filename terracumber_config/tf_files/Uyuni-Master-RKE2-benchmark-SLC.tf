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
  uri = "qemu+tcp://moscowmule.mgr.slc1.suse.org/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "uyuni-master"

  // Kubernetes variables
  kubernetes                     = true
  use_devel_oci                  = false
  install_mlm_server             = false
  install_mlm_proxy              = false
  install_traefik                = false
  install_local_path_provisioner = false
  deploy_coco_attestation        = false
  deploy_saline                  = false
  deploy_tftp                    = false
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
  name_prefix  = "uyuni-benchmark-master-"
  domain       = "mgr.slc1.suse.org"
  from_email   = "root@suse.de"
  
  container_server = true
  container_proxy  = true

  mirror                   = "minima-mirror-ci-bv.mgr.slc1.suse.org"
  use_mirror_images        = true

  # server_http_proxy = "http-proxy.mgr.slc1.suse.org:3128"
  custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.slc1.suse.org:445"

  # when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac = "aa:b2:93:04:09:00"
      }
    }
    server_kubernetes = {
      image = "tumbleweedo"
      provider_settings = {
        mac = "aa:b2:93:04:09:01"
        vcpu = 8
        memory = 32768
      }
      runtime                        = "rke2"
      container_tag                  = "latest"
      container_registry             = "registry.opensuse.org/systemsmanagement/uyuni/master/containerfile/uyuni"
      helm_chart_name                = "server-helm"
      helm_chart_url                 = "oci://registry.opensuse.org/systemsmanagement/uyuni/master/charts/uyuni"

      login_timeout = 28800
      main_disk_size = 40
      repository_disk_size = 300
      database_disk_size = 60
    }
  }
  
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = "br1"
    additional_network = "192.168.101.0/24"
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
