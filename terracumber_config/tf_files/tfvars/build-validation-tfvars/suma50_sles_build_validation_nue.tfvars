ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:02:03:e8"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:93:02:03:e9"
    name  = "server"
    image = "sles15sp6o"
    string_registry = false
  }
  proxy_containerized = {
    mac   = "aa:b2:93:02:03:ea"
    name  = "proxy"
    image = "sles15sp6o"
    string_registry = false
  }

  # Standard Minions
  sles15sp7_minion = {
    mac  = "aa:b2:93:02:03:eb"
    name = "sles15sp7-minion"
  }
  product_version = "5.0-released"
  name_prefix     = "suma-bv-50-sles-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-5.0/job/manager-5.0-sles-qe-build-validation"
}
BASE_CONFIGURATIONS = {
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
