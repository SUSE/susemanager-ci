variable "CONTAINER_REPOSITORY" {
  type = string
  description = "Container repository for server and proxy"
  default = "registry.suse.de"
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

  product_version = "head"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH
  cc_ptf_username = var.SCC_PTF_USER
  cc_ptf_password = var.SCC_PTF_PASSWORD

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["rocky8o", "opensuse156o", "ubuntu2404o", "sles15sp7o", "slmicro61o"]

  use_avahi    = false
  name_prefix  = "${var.ENVIRONMENT}-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry       = "registry.mgr.suse.de"
  auth_registry          = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo      = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/temporary"

  container_server = true
  container_proxy  = true
  beta_enabled = false

  mirror                   = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images        = true

  server_http_proxy        = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.suse.de:445"

  kubernetes                     = true
  use_devel_oci                  = true
  install_mlm_server             = true
  install_mlm_proxy              = true
  install_traefik                = true
  install_local_path_provisioner = true

  # when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["controller"]
        vcpu = 4
        memory = 4096
      }
    }
    server_kubernetes = {
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["server"]
        vcpu   = 2
        memory = 16384
      }
      main_disk_size       = 500
      login_timeout        = 28800
      large_deployment     = true
      runtime              = "rke2"
      container_tag        = "latest"
      container_repository = "registry.suse.de/suse/containers/suse-multilinuxmanager/5.2/containers/suse/multi-linux-manager/5.2/x86_64/server"
      helm_chart_name      = "server-helm"
      helm_chart_url       = "oci://registry.suse.com/suse/multi-linux-manager/5.2"
    }
    proxy_kubernetes = {
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["proxy"]
        vcpu = 2
        memory = 16384
      }
      main_disk_size       = 200
      runtime              = "rke2"
      container_tag        = "latest"
      container_repository = "registry.suse.de/suse/containers/suse-multilinuxmanager/5.2/containers/suse/multi-linux-manager/5.2/x86_64/proxy"
      helm_chart_name      = "proxy-helm"
      helm_chart_url       = "oci://registry.suse.com/suse/multi-linux-manager/5.2"
    }
    suse_minion = {
      image = "sles15sp7o"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["suse-minion"]
        vcpu = 2
        memory = 2048
      }
    }
    suse_sshminion = {
      image = "sles15sp7o"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["suse-sshminion"]
        vcpu = 2
        memory = 2048
      }
    }
    rhlike_minion = {
      image = "rocky8o"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["rhlike-minion"]
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Also, openscap cannot run with less than 1.25 GB of RAM
        vcpu = 2
        memory = 2048
      }
    }
    deblike_minion = {
      image = "ubuntu2404o"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["deblike-minion"]
        vcpu = 2
        memory = 2048
      }
    }
    build_host = {
      image = "sles15sp7o"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["build-host"]
        vcpu = 2
        memory = 2048
      }
    }
    pxeboot_minion = {
      image = "sles15sp7o"
    }
    dhcp_dns = {
      name        = "dhcp-dns"
      image       = "opensuse156o"
      hypervisor  = {
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
