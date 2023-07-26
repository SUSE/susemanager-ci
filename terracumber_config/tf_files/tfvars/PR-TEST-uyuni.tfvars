############ Uyuni unique variables ########################

IMAGE                  = "opensuse154-ci-pro"
IMAGES                 = ["rocky8o", "opensuse154o", "opensuse154-ci-pro", "ubuntu2204o"]
SUSE_MINION_IMAGE      = "opensuse154o"
SUSE_MINION_NAME       = "leap15"
PRODUCT_VERSION        = "uyuni-pr"
MAIL_TEMPLATE_ENV_FAIL = "../mail_templates/mail-template-jenkins-pull-request-env-fail.txt"
MAIL_TEMPLATE          = "../mail_templates/mail-template-jenkins-pull-request.txt"
MAIL_SUBJECT           = "$status acceptance tests on Pull Request: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
CUCUMBER_BRANCH        = "master"
CUCUMBER_GITREPO       = "https://github.com/uyuni-project/uyuni.git"
CUCUMBER_COMMAND       = "export PRODUCT='Uyuni' && run-testsuite"
URL_PREFIX             = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-prs-ci-tests"
ADDITIONAL_REPOS_ONLY  = true
REDHAT_MINION_IMAGE    = "rocky8o"
REDHAT_MINION_NAME     = "rocky8"
ADDITIONAL_REPOS = {
  server = {
    pull_request_repo = "${var.PULL_REQUEST_REPO}"
    master_repo = "${var.MASTER_REPO}"
    master_repo_other = "${var.MASTER_OTHER_REPO}"
    master_sumaform_tools_repo = "${var.MASTER_SUMAFORM_TOOLS_REPO}"
    test_packages_repo = "${var.TEST_PACKAGES_REPO}"
    non_os_pool = "http://${var.MIRROR}/distribution/leap/15.4/repo/non-oss/"
    os_pool = "http://${var.MIRROR}/distribution/leap/15.4/repo/oss/"
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
    non_os_pool = "http://${var.MIRROR}/distribution/leap/15.4/repo/non-oss/"
    os_pool = "http://${var.MIRROR}/distribution/leap/15.4/repo/oss/"
    os_update = "${var.UPDATE_REPO}"
    os_additional_repo = "${var.ADDITIONAL_REPO_URL}"
    testing_overlay_devel = "http://${var.MIRROR}/repositories/systemsmanagement:/Uyuni:/Master/images/repo/Testing-Overlay-POOL-x86_64-Media1/"
    proxy_pool = "http://${var.MIRROR}/repositories/systemsmanagement:/Uyuni:/Master/images/repo/Uyuni-Proxy-POOL-x86_64-Media1/"
    tools_update_pr = "${var.OPENSUSE_CLIENT_REPO}"
  }
  suse-minion = {
    tools_update_pr = "${var.OPENSUSE_CLIENT_REPO}"
  }
  kvm-host = {
    client_repo = "${var.OPENSUSE_CLIENT_REPO}"
    master_sumaform_tools_repo = "${var.MASTER_SUMAFORM_TOOLS_REPO}"
    test_packages_repo = "${var.TEST_PACKAGES_REPO}"
    non_os_pool = "http://${var.MIRROR}/distribution/leap/15.4/repo/non-oss/"
    os_pool = "http://${var.MIRROR}/distribution/leap/15.4/repo/oss/"
    os_update = "${var.UPDATE_REPO}"
    os_additional_repo = "${var.ADDITIONAL_REPO_URL}"
    tools_update_pr = "${var.SLE_CLIENT_REPO}"
  }
}