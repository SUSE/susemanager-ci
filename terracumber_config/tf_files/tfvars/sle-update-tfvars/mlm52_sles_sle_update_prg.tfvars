ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:02:03:c4"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:93:02:03:c5"
    name  = "server"
    image = "sles15sp7o"
    string_registry = true
  }
  proxy_containerized = {
    mac   = "aa:b2:93:02:03:c6"
    name  = "proxy"
    image = "sles15sp7o"
    string_registry = true
  }

  # Standard Minions
  sles15sp7_minion = {
    mac  = "aa:b2:93:02:03:c7"
    name = "sles15sp7-minion"
  }

  product_version = "5.2-released"
  name_prefix     = "mlm-su-52-sles-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-5.2/job/manager-5.2-qe-mi-validation-bci"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br1"
    hypervisor         = "suma-11.mgr.suse.de"
    additional_network = null
    images              = ["sles15sp7o", "opensuse156o"]
  }
}
MAIL_SUBJECT          = "Results 5.2 SLE Update $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.2 SLE Update: Environment setup failed"
LOCATION              = "nue"
