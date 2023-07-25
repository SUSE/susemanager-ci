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
