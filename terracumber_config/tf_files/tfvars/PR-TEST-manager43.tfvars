############ Spacewalk unique variables ###########

IMAGE                  = "sles15sp4o"
IMAGES                 = ["rocky8o", "opensuse154o", "sles15sp4o", "ubuntu2204o"]
SUSE_MINION_IMAGE      = "sles15sp4o"
SUSE_MINION_NAME       = "sles15"
PRODUCT_VERSION        = "4.3-nightly"
MAIL_TEMPLATE_ENV_FAIL = "../mail_templates/mail-template-jenkins-suma43-pull-request-env-fail.txt"
MAIL_TEMPLATE          = "../mail_templates/mail-template-jenkins-suma43-pull-request.txt"
MAIL_SUBJECT           = "$status acceptance tests on SUMA 4.3 Pull Request: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
CUCUMBER_BRANCH        = "Manager-4.3"
CUCUMBER_GITREPO       = "https://github.com/SUSE/spacewalk/spacewalk.git"
CUCUMBER_COMMAND       = "export PRODUCT='SUSE-Manager' && run-testsuite"
URL_PREFIX             = "https://ci.suse.de/view/Manager/view/Uyuni/job/suma43-prs-ci-tests"
ADDITIONAL_REPOS_ONLY  = false
