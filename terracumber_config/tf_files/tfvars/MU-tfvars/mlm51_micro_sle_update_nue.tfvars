ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:02:03:f0"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:93:02:03:f1"
    name  = "server"
    image = "slmicro61o"
  }
  proxy_containerized = {
    mac   = "aa:b2:93:02:03:f2"
    name  = "proxy"
    image = "slmicro61o"
  }

  # Standard Minions
  sles15sp6_minion = {
    mac  = "aa:b2:93:02:03:f3"
    name = "sles15sp6-minion"
  }

  product_version = "5.1-released"
  name_prefix     = "mlm-su-51micro-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-5.1/job/manager-5.1-micro-qe-sle-update-NUE"

  base_core = {
    pool       = "ssd"
    bridge     = "br1"
    hypervisor = "suma-11.mgr.suse.de"
    # additional_network is not defined
  }
}

# Cucumber Overrides
CUCUMBER_GITREPO = "https://github.com/SUSE/spacewalk.git"
CUCUMBER_BRANCH  = "Manager-5.1"

MAIL_SUBJECT          = "Results 5.1 SLE Update $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.1 SLE Update: Environment setup failed"
LOCATION              = "nue"