variable "CONTAINER_REPOSITORY" {
  type = string
  description = "Container repository for server and proxy"
  default = "registry.opensuse.org/systemsmanagement/uyuni/master/containerfile"
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
  uri = "qemu+tcp://${var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].hypervisor}/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "uyuni-master"

  // Cucumber repository configuration for the controller
  git_username  = var.GIT_USER
  git_password  = var.GIT_PASSWORD
  git_repo      = var.CUCUMBER_GITREPO
  branch        = var.CUCUMBER_BRANCH
  cc_ptf_username = var.SCC_PTF_USER
  cc_ptf_password = var.SCC_PTF_PASSWORD

  cc_username   = var.SCC_USER
  cc_password   = var.SCC_PASSWORD

  images        = ["rocky8o", "opensuse156o", "ubuntu2404o", "sles15sp7o", "tumbleweedo"]

  use_avahi     = false
  name_prefix   = "${var.ENVIRONMENT}-"
  domain        = "mgr.suse.de"
  from_email    = "root@suse.de"

  no_auth_registry          = "registry.mgr.suse.de"
  auth_registry             = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username    = "cucutest"
  auth_registry_password    = "cucusecret"
  git_profiles_repo         = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/temporary"

  container_server          = true
  container_proxy           = true

  mirror                    = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images         = true
  server_http_proxy         = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint  = "ftp://minima-mirror-ci-bv.mgr.suse.de:445"

  # when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac       = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["controller"]
        memory    = 4096
        vcpu      = 4
        cpu_model = "host-passthrough"
      }
    }
    server_containerized = {
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["server"]
      }
      runtime               = "podman"
      container_repository  = var.CONTAINER_REPOSITORY
      container_tag         = "latest"
      helm_chart_url        = "oci://registry.opensuse.org/systemsmanagement/uyuni/master/charts/uyuni/server"
      main_disk_size        = 50
      repository_disk_size  = 150
      database_disk_size    = 50
      login_timeout         = 28800
      large_deployment      = true
    }
    proxy_containerized = {
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["proxy"]
      }
      runtime              = "podman"
      container_repository = var.CONTAINER_REPOSITORY
      container_tag        = "latest"
    }
    suse_minion = {
      image             = "tumbleweedo"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["suse-minion"]
      }
    }
    suse_sshminion = {
      image             = "tumbleweedo"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["suse-sshminion"]
      }
    }
    rhlike_minion = {
      image             = "rocky8o"
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["rhlike-minion"]
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Also, openscap cannot run with less than 1.25 GB of RAM
        vcpu   = 2
        memory = 2048
      }
    }
    deblike_minion = {
      image             = "ubuntu2404o"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["deblike-minion"]
      }
    }
    build_host = {
      image             = "sles15sp7o"
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["build-host"]
        memory = 2048
      }
    }
    pxeboot_minion = {
      image = "sles15sp7o"
    }
    dhcp_dns = {
      name       = "dhcp-dns"
      image      = "opensuse156o"
      hypervisor = {
        host        = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].hypervisor
        user        = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].dhcp_user
        private_key = file("~/.ssh/id_ed25519")
      }
    }
  }
  provider_settings = {
    pool               = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].pool
    network_name       = null
    bridge             = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].bridge
    additional_network = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].additional_network
  }
}


output "configuration" {
  value = module.cucumber_testsuite.configuration
}
