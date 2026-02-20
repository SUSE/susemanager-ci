ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:02:03:e4"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:93:02:03:e5"
    name  = "server"
    image = "sles15sp6o"
    string_registry = false
  }
  proxy_containerized = {
    mac   = "aa:b2:93:02:03:e6"
    name  = "proxy"
    image = "sles15sp6o"
    string_registry = false
  }

  # Standard Minions
  sles15sp6_minion = {
    mac  = "aa:b2:93:02:03:e7"
    name = "sles15sp6-minion"
  }

  product_version = "5.0-released"
  name_prefix     = "suma-su-50-sles-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-5.0/job/manager-5.0-qe-mi-validation-bci"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br1"
    hypervisor         = "suma-11.mgr.suse.de"
    additional_network = null
    images             = [ "sles15sp6o", "opensuse156o", "sles15sp6o" ]
  }
}
MAIL_SUBJECT          = "Results 5.0 SLE Update $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.0 SLE Update: Environment setup failed"
LOCATION              = "nue"
