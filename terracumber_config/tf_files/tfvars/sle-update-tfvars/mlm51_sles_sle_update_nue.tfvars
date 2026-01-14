ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:02:03:f4"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:93:02:03:f5"
    name  = "server"
    image = "sles15sp7o"
    string_registry = true
  }
  proxy_containerized = {
    mac   = "aa:b2:93:02:03:f6"
    name  = "proxy"
    image = "sles15sp7o"
    string_registry = true
  }

  # Standard Minions
  sles15sp6_minion = {
    mac  = "aa:b2:93:02:03:f7"
    name = "sles15sp6-minion"
  }

  product_version = "5.1-released"
  name_prefix     = "mlm-su-51sles-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-5.1/job/manager-5.1-sles-qe-sle-update-NUE"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br1"
    hypervisor         = "suma-11.mgr.suse.de"
    additional_network = null
    images              = ["sles15sp6o", "opensuse156o", "sles15sp7o"]
  }
}
MAIL_SUBJECT          = "Results 5.1 SLE Update $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.1 SLE Update: Environment setup failed"
LOCATION              = "nue"
