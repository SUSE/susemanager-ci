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
  uri = "qemu+tcp://${var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].hypervisor}/system"
}

module "cucumber_testsuite" {
  source = "./modules/cucumber_testsuite"

  product_version = var.PRODUCT_VERSION

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  mirror      = var.MIRROR
  use_mirror_images = var.USE_MIRROR_IMAGES

  images = var.IMAGES

  use_avahi    = false
  name_prefix  = "suma-pr${var.ENVIRONMENT}-"
  domain       = var.DOMAIN
  from_email   = "root@suse.de"

  no_auth_registry = "registry.${var.DOMAIN}"
  auth_registry      = "registry.${var.DOMAIN}:5000/cucutest"
  auth_registry_username = "cucutest"
  auth_registry_password = "cucusecret"
  git_profiles_repo = var.GIT_PROFILES_REPO
  container_server = true
  container_proxy  = true

  server_http_proxy = "http-proxy.${var.DOMAIN}:3128"
  custom_download_endpoint = "ftp://${var.DOWNLOAD_ENDPOINT}:445"

  # when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["controller"]
        vcpu = 2
        memory = 2048
      }
    }
    dhcp-dns = {
      name = "dhcp-dns"
      image = "opensuse155o"
      hypervisor = {
        host        = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].hypervisor
        user        = "root"
        private_key = file("~/.ssh/id_rsa")
    }
    server_containerized = {
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["server"]
        vcpu = 8
        memory = 32768
      }
      main_disk_size       = 400
      runtime = "podman"
      container_repository = "registry.opensuse.org/systemsmanagement/uyuni/master/containers_leap_15.6"
      helm_chart_url = "oci://registry.opensuse.org/systemsmanagement/uyuni/master/charts/uyuni/server"
      login_timeout = 28800
      additional_repos_only = var.ADDITIONAL_REPOS_ONLY
      additional_repos = local.additional_repos["server"]
      image = var.SERVER_IMAGE
      server_mounted_mirror = var.MIRROR
      main_disk_size = 500
    }
    proxy_containerized = {
      container_repository = "registry.opensuse.org/systemsmanagement/uyuni/master/containers_leap_15.6"
      container_tag = "latest"
      image = var.PROXY_IMAGE
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["proxy"]
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
      runtime = "podman"
    }
    suse-minion = {
      image = var.SUSE_MINION_IMAGE
      name = "min-suse"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["suse-minion"]
        vcpu = 2
        memory = 2048
      }
      additional_repos = local.additional_repos["suse-minion"]
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = var.SUSE_MINION_IMAGE
      name = "minssh-suse"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["suse-sshminion"]
        vcpu = 2
        memory = 2048
      }
      additional_repos = local.additional_repos["suse-minion"]
      additional_packages = [ "venv-salt-minion", "iptables" ]
      install_salt_bundle = true
    }
    redhat-minion = {
      image = var.RHLIKE_MINION_IMAGE
      name = "min-rhlike"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["rhlike-minion"]
        memory = 2048
        vcpu = 2
      }
      additional_repos = {
        client_repo = var.RHLIKE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    debian-minion = {
      image = var.DEBLIKE_MINION_IMAGE
      name = "min-deblike"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["deblike-minion"]
        vcpu = 2
        memory = 2048
      }
      additional_repos = {
        client_repo = var.DEBLIKE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      // FIXME: cloudl-init fails if venv-salt-minion is not avaiable
      // We can set "install_salt_bundle = true" as soon as venv-salt-minion is available Uyuni:Stable
      install_salt_bundle = true
    }
    build-host = {
      image = "sles15sp4o"
      name = "min-build"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["build-host"]
        memory = 2048
      }
      additional_repos = {
        tools_update_pr = var.SLE_CLIENT_REPO
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    pxeboot-minion = {
      image = "sles15sp4o"
      additional_repos = {
        tools_update_pr = var.SLE_CLIENT_REPO
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    kvm-host = {
      image = var.IMAGE
      name = "min-kvm"
      
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["kvm-host"]
      }
      additional_repos_only = var.ADDITIONAL_REPOS_ONLY
      additional_repos = local.additional_repos["kvm-host"]
      additional_packages = [ "venv-salt-minion", "mkisofs" ]
      install_salt_bundle = true
    }
  }
  
  provider_settings = {
    pool               = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].pool
    network_name       = null
    bridge             = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].bridge
    additional_network = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].additional_network
  }
}


resource "null_resource" "add_test_information" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "file" {
    source      = "../../susemanager-ci/terracumber_config/scripts/set_custom_header.sh"
    destination = "/tmp/set_custom_header.sh"
    connection {
      type     = "ssh"
      user     = "root"
      password = "linux"
      host     = "${module.cucumber_testsuite.configuration.server.hostname}"
    }
  }
}

output "configuration" {
  value = module.cucumber_testsuite.configuration
}
