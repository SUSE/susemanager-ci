ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:02:03:c8"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:93:02:03:c9"
    name  = "server"
    image = "slmicro62o"
    string_registry = true
  }
  proxy_containerized = {
    mac   = "aa:b2:93:02:03:ca"
    name  = "proxy"
    image = "slmicro62o"
    string_registry = true
  }

  # Standard Minions
  sles15sp7_minion = {
    mac  = "aa:b2:93:02:03:cb"
    name = "sles15sp7-minion"
  }
  # TODO: use final value
  product_version = "head"
  # product_version = "5.2-released"
  name_prefix     = "mlm-bv-52-micro-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-5.2/job/manager-5.2-micro-qe-build-validation"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br1"
    hypervisor         = "suma-11.mgr.suse.de"
    additional_network = null
  }
}
MAIL_SUBJECT          = "Results 5.2 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.2 Build Validation: Environment setup failed"
LOCATION              = "nue"
