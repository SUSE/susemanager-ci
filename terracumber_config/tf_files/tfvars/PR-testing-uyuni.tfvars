############ Uyuni unique variables ############

IMAGE                  = "opensuse155-ci-pro"
SERVER_IMAGE           = "leapmicro55o"
PROXY_IMAGE            = "opensuse155o"
IMAGES                 = ["rocky9o", "opensuse155o", "opensuse155-ci-pro", "ubuntu2204o", "sles15sp4o", "leapmicro55o"]
SUSE_MINION_IMAGE      = "opensuse155o"
PRODUCT_VERSION        = "uyuni-pr"
MAIL_TEMPLATE_ENV_FAIL = "../../mail_templates/mail-template-jenkins-pull-request-env-fail.txt"
MAIL_TEMPLATE          = "../../mail_templates/mail-template-jenkins-pull-request.txt"
MAIL_SUBJECT           = "$status acceptance tests on Pull Request: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
CUCUMBER_BRANCH        = "master"
CUCUMBER_GITREPO       = "https://github.com/uyuni-project/uyuni.git"
CUCUMBER_COMMAND       = "export PRODUCT='Uyuni' && run-testsuite"
URL_PREFIX             = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-prs-ci-tests"
ADDITIONAL_REPOS_ONLY  = true
RHLIKE_MINION_IMAGE    = "rocky9o"
DEBLIKE_MINION_IMAGE   = "ubuntu2204o"
