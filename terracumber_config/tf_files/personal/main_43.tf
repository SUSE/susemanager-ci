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
  uri = "qemu+tcp://suma-05.mgr.suse.de/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = "4.3-nightly"

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD

  images = ["rocky8o", "opensuse155o", "opensuse156o", "sles15sp4o", "ubuntu2204o"]

  use_avahi    = false
  name_prefix  = "${var.ENVIRONMENT}-"
  domain       = "mgr.suse.de"
  from_email   = "root@suse.de"

  no_auth_registry       = "registry.mgr.suse.de"
  auth_registry          = "registry.mgr.suse.de:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo      = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"

  mirror                   = "minima-mirror-ci-bv.mgr.suse.de"
  use_mirror_images        = true
  server_http_proxy        = "http-proxy.mgr.suse.de:3128"
  custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.suse.de:445"

  # when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["controller"]
        vcpu   = 4
        memory = 4096
      }
    }
    server = {
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["server"]
        vcpu   = 8
        memory = 32768
      }
      main_disk_size       = 20
      repository_disk_size = 150
      database_disk_size   = 50
      large_deployment     = true
    }
    proxy = {
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["proxy"]
        vcpu   = 2
        memory = 2048
      }
    }
    suse_client = {
      image = "sles15sp4o"
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["suse-client"]
        vcpu   = 2
        memory = 2048
      }
    }
    suse_minion = {
      image = "sles15sp4o"
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["suse-minion"]
        vcpu   = 2
        memory = 2048
      }
    }
    suse_sshminion = {
      image = "sles15sp4o"
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["suse-sshminion"]
        vcpu   = 2
        memory = 2048
      }
    }
    rhlike_minion = {
      image = "rocky8o"
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["rhlike-minion"]
        // Since start of May we have problems with the instance not booting after a restart if there is only a CPU and only 1024Mb for RAM
        // Also, openscap cannot run with less than 1.25 GB of RAM
        vcpu   = 2
        memory = 2048
      }
    }
    deblike_minion = {
      image = "ubuntu2204o"
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["deblike-minion"]
        vcpu   = 2
        memory = 2048
      }
    }
    build_host = {
      image = "sles15sp4o"
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["build-host"]
        vcpu   = 2
        memory = 2048
      }
    }
    pxeboot_minion = {
      image = "sles15sp4o"
      provider_settings = {
        vcpu   = 2
        memory = 2048
      }
    }
    kvm_host = {
      image = "sles15sp4o"
      provider_settings = {
        mac    = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["kvm-host"]
        vcpu   = 2
        memory = 4048
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
