ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:02:03:e0"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:93:02:03:e1"
    name  = "server"
    image = "slemicro55o"
  }
  proxy_containerized = {
    mac   = "aa:b2:93:02:03:e2"
    name  = "proxy"
    image = "slemicro55o"
  }

  # Standard Minions
  sles15sp6_minion = {
    mac  = "aa:b2:93:02:03:e3"
    name = "sles15sp6-minion"
  }

  product_version = "5.0-released"
  name_prefix     = "suma-su-50micro-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-5.0/job/manager-5.0-micro-qe-sle-update-NUE"

  base_core = {
    pool               = "ssd"
    bridge             = "br1"
    hypervisor         = "suma-11.mgr.suse.de"
    additional_network = null
  }
}

MAIL_SUBJECT          = "Results 5.0 SLE Update $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.0 SLE Update: Environment setup failed"
LOCATION              = "nue"