locals {
  additional_repos = var.PRODUCT_VERSION == "uyuni-pr" ? {
    server = {
      pull_request_repo = "${var.PULL_REQUEST_REPO}"
      master_repo = "${var.MASTER_REPO}"
      master_repo_other = "${var.MASTER_OTHER_REPO}"
      master_sumaform_tools_repo = "${var.MASTER_SUMAFORM_TOOLS_REPO}"
      test_packages_repo = "${var.TEST_PACKAGES_REPO}"
      non_os_pool = "http://${var.MIRROR}/distribution/leap/15.5/repo/non-oss/"
      os_pool = "http://${var.MIRROR}/distribution/leap/15.5/repo/oss/"
      os_update = "${var.UPDATE_REPO}"
      os_additional_repo = "${var.ADDITIONAL_REPO_URL}"
      testing_overlay_devel = "http://${var.MIRROR}/repositories/systemsmanagement:/Uyuni:/Master/images/repo/Testing-Overlay-POOL-x86_64-Media1/"
    }
    proxy = {
      pull_request_repo = "${var.PULL_REQUEST_REPO}"
      master_repo = "${var.MASTER_REPO}"
      master_repo_other = "${var.MASTER_OTHER_REPO}"
      master_sumaform_tools_repo = "${var.MASTER_SUMAFORM_TOOLS_REPO}"
      test_packages_repo = "${var.TEST_PACKAGES_REPO}"
      non_os_pool = "http://${var.MIRROR}/distribution/leap/15.5/repo/non-oss/"
      os_pool = "http://${var.MIRROR}/distribution/leap/15.5/repo/oss/"
      os_update = "${var.UPDATE_REPO}"
      os_additional_repo = "${var.ADDITIONAL_REPO_URL}"
      testing_overlay_devel = "http://${var.MIRROR}/repositories/systemsmanagement:/Uyuni:/Master/images/repo/Testing-Overlay-POOL-x86_64-Media1/"
      proxy_pool = "http://${var.MIRROR}/repositories/systemsmanagement:/Uyuni:/Master/images/repo/Uyuni-Proxy-POOL-x86_64-Media1/"
      tools_update_pr = "${var.OPENSUSE_CLIENT_REPO}"
    }
    suse-minion = {
      tools_update_pr = "${var.SLE_CLIENT_REPO}"
    }
    kvm-host = {
      client_repo = "${var.OPENSUSE_CLIENT_REPO}"
      master_sumaform_tools_repo = "${var.MASTER_SUMAFORM_TOOLS_REPO}"
      test_packages_repo = "${var.TEST_PACKAGES_REPO}"
      non_os_pool = "http://${var.MIRROR}/distribution/leap/15.5/repo/non-oss/"
      os_pool = "http://${var.MIRROR}/distribution/leap/15.5/repo/oss/"
      os_update = "${var.UPDATE_REPO}"
      os_additional_repo = "${var.ADDITIONAL_REPO_URL}"
    }
  } : {
    server = {
      pull_request_repo = "${var.PULL_REQUEST_REPO}"
    }
    proxy = {
      pull_request_repo = "${var.PULL_REQUEST_REPO}"
    }
    suse-minion = {
      tools_update_pr = "${var.SLE_CLIENT_REPO}"
    }
    kvm-host = {
      tools_update_pr = "${var.SLE_CLIENT_REPO}"
    }
  }
}
