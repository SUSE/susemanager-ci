ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:02:03:f8"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:93:02:03:f9"
    name  = "server"
    image = "sles15sp7o"
    string_registry = true
  }
  proxy_containerized = {
    mac   = "aa:b2:93:02:03:fa"
    name  = "proxy"
    image = "sles15sp7o"
    string_registry = true
  }

  # Standard Minions
  sles15sp6_minion = {
    mac  = "aa:b2:93:02:03:fb"
    name = "sles15sp6-minion"
  }
  product_version = "5.1-released"
  name_prefix     = "mlm-bv-51sles-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-5.1/job/manager-5.1-sles-qe-build-validation-NUE"
}
BASE_CONFIGURATIONS   = {
  base_core = {
    pool               = "ssd"
    bridge             = "br1"
    hypervisor         = "suma-11.mgr.suse.de"
    additional_network = null
  }
}
MAIL_SUBJECT          = "Results 5.1 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.1 Build Validation: Environment setup failed"
LOCATION              = "nue"
