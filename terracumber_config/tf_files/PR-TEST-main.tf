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
  use_mirror_images = var.USE_MIRROR

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

  server_http_proxy = "http-proxy.${var.DOMAIN}:3128"
  custom_download_endpoint = "ftp://${var.MIRROR}:445"

  # when changing images, please also keep in mind to adjust the image matrix at the end of the README.
  host_settings = {
    controller = {
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["controller"]
      }
    }
    server = {
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["server"]
      }
      additional_repos_only = var.ADDITIONAL_REPOS_ONLY
      additional_repos = {
        pull_request_repo = var.PULL_REQUEST_REPO,
        master_repo = var.MASTER_REPO,
        master_repo_other = var.MASTER_OTHER_REPO,
        master_sumaform_tools_repo = var.MASTER_SUMAFORM_TOOLS_REPO,
        test_packages_repo = var.TEST_PACKAGES_REPO,
        non_os_pool = "http://${var.MIRROR}/distribution/leap/15.4/repo/non-oss/",
        os_pool = "http://${var.MIRROR}/distribution/leap/15.4/repo/oss/",
        os_update = var.UPDATE_REPO,
        os_additional_repo = var.ADDITIONAL_REPO_URL,
        testing_overlay_devel = "http://${var.MIRROR}/repositories/systemsmanagement:/Uyuni:/Master/images/repo/Testing-Overlay-POOL-x86_64-Media1/",
      }
      image = var.IMAGE
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
      server_mounted_mirror = var.MIRROR
    }
    proxy = {
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["proxy"]
      }
      additional_repos_only = var.ADDITIONAL_REPOS_ONLY
      additional_repos = {
        pull_request_repo = var.PULL_REQUEST_REPO,
        master_repo = var.MASTER_REPO,
        master_repo_other = var.MASTER_OTHER_REPO,
        master_sumaform_tools_repo = var.MASTER_SUMAFORM_TOOLS_REPO,
        test_packages_repo = var.TEST_PACKAGES_REPO,
        non_os_pool = "http://${var.MIRROR}/distribution/leap/15.4/repo/non-oss/",
        os_pool = "http://${var.MIRROR}/distribution/leap/15.4/repo/oss/",
        os_update = var.UPDATE_REPO,
        os_additional_repo = var.ADDITIONAL_REPO_URL,
        testing_overlay_devel = "http://${var.MIRROR}/repositories/systemsmanagement:/Uyuni:/Master/images/repo/Testing-Overlay-POOL-x86_64-Media1/",
        proxy_pool = "http://${var.MIRROR}/repositories/systemsmanagement:/Uyuni:/Master/images/repo/Uyuni-Proxy-POOL-x86_64-Media1/",
        tools_update = var.OPENSUSE_CLIENT_REPO
      }
      image = var.IMAGE
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-minion = {
      image = "sles15sp4o"
      name = "min-sles15"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["suse-minion"]
      }
      additional_repos = {
        tools_update = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    suse-sshminion = {
      image = "sles15sp4o"
      name = "minssh-sles15"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["suse-sshminion"]
      }
      additional_repos = {
        tools_update = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion", "iptables" ]
      install_salt_bundle = true
    }
    redhat-minion = {
      image = "rocky8o"
      name = "min-rocky8"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["redhat-minion"]
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
      image = "ubuntu2204o"
      name = "min-ubuntu2204"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["debian-minion"]
      }
      additional_repos = {
        client_repo = var.DEBLIKE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      // FIXME: cloudl-init fails if venv-salt-minion is not avaiable
      // We can set "install_salt_bundle = true" as soon as venv-salt-minion is available Uyuni:Stable
      install_salt_bundle = false
    }
    build-host = {
      image = "sles15sp4o"
      name = "min-build"
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["build-host"]
        memory = 2048
      }
      additional_repos = {
        tools_update = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    pxeboot-minion = {
      image = "sles15sp4o"
      additional_repos = {
        tools_update = var.SLE_CLIENT_REPO,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
    kvm-host = {
      image = var.IMAGE
      name = "min-kvm"
      additional_grains = {
        hvm_disk_image = {
          leap = {
            hostname = "suma-pr${var.ENVIRONMENT}-min-nested"
            image = "http://${var.MIRROR}/distribution/leap/15.4/appliances/openSUSE-Leap-15.4-JeOS.x86_64-OpenStack-Cloud.qcow2"
            hash = "http://${var.MIRROR}/distribution/leap/15.4/appliances/openSUSE-Leap-15.4-JeOS.x86_64-OpenStack-Cloud.qcow2.sha256"
          }
          sles = {
            hostname = "suma-pr${var.ENVIRONMENT}-min-nested"
            image = "http://${var.MIRROR}/install/SLE-15-SP4-Minimal-GM/SLES15-SP4-Minimal-VM.x86_64-OpenStack-Cloud-GM.qcow2"
            hash = "http://${var.MIRROR}/install/SLE-15-SP4-Minimal-GM/SLES15-SP4-Minimal-VM.x86_64-OpenStack-Cloud-GM.qcow2.sha256"
          }
        }
      }
      provider_settings = {
        mac = var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["kvm-host"]
      }
      additional_repos_only = true
      additional_repos = {
        client_repo = var.OPENSUSE_CLIENT_REPO,
        master_sumaform_tools_repo = var.MASTER_SUMAFORM_TOOLS_REPO,
        test_packages_repo = var.TEST_PACKAGES_REPO,
        non_os_pool = "http://${var.MIRROR}/distribution/leap/15.4/repo/non-oss/",
        os_pool = "http://${var.MIRROR}/distribution/leap/15.4/repo/oss/",
        os_update = var.UPDATE_REPO,
        os_additional_repo = var.ADDITIONAL_REPO_URL,
      }
      additional_packages = [ "venv-salt-minion" ]
      install_salt_bundle = true
    }
  }
  nested_vm_host = "suma-pr${var.ENVIRONMENT}-min-nested"
  nested_vm_mac =  var.ENVIRONMENT_CONFIGURATION[var.ENVIRONMENT].mac["nested-vm"]
  provider_settings = {
    pool               = "ssd"
    network_name       = null
    bridge             = var.BRIDGE
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
