ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:02:03:d0"
    name = "controller"
  }
  server = {
    mac  = "aa:b2:93:02:03:d1"
    name = "server"
  }
  proxy = {
    mac  = "aa:b2:93:02:03:d2"
    name = "proxy"
  }

  # Standard Minions
  sles15sp4_minion = {
    mac  = "aa:b2:93:02:03:d3"
    name = "sles15sp4-minion"
  }

  product_version = "4.3-released"
  name_prefix     = "suma-su-43-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-4.3/job/manager-4.3-qe-sle-update-NUE"
}
BASE_CONFIGURATIONS {
  base_core = {
    pool                = "ssd"
    bridge              = "br1"
    hypervisor          = "suma-11.mgr.suse.de"
    additional_network  = null
    images              = ["sles15sp4o", "opensuse156o"]
  }
}
MAIL_SUBJECT          = "Results 4.3 SLE Update $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 4.3 SLE Update: Environment setup failed"
LOCATION              = "nue"
