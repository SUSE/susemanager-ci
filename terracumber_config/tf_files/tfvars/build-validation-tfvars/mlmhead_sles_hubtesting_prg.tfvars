ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:01:01:30"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:93:01:01:31"
    name  = "hub"
    image = "sles15sp7o"
    string_registry = true
  }
  server2_containerized = {
    mac   = "aa:b2:93:01:01:32"
    name  = "prh1"
    image = "sles15sp7o"
    string_registry = true
  }
  server3_containerized = {
    mac   = "aa:b2:93:01:01:33"
    name  = "prh2"
    image = "sles15sp7o"
    string_registry = true
  }
  proxy_containerized = {
    mac   = "aa:b2:93:01:01:34"
    name  = "proxy"
    image = "sles15sp7o"
    string_registry = true
  }

  # Standard Minions
  sles15sp5_minion = {
    mac  = "aa:b2:93:01:01:35"
    name = "sles15sp5-minion"
  }
  sles15sp7_minion = {
    mac  = "aa:b2:93:01:01:36"
    name = "sles15sp7-minion"
  }
  monitoring_server = {
    mac  = "aa:b2:93:01:01:37"
    name = "monitoring"
    image = "sles15sp7o"
  }

  product_version      = "head"
  name_prefix          = "mlm-testhub-"
  url_prefix           = "https://jenkins.mgr.suse.de/job/manager-qe-test-hub-acceptance-tests"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br0"
    hypervisor         = "cthulhu.mgr.suse.de"
    additional_network = null
    images             = ["sles15sp7o", "opensuse156o", "sles15sp5o"]
  }
}
MAIL_SUBJECT          = "Results 5.2 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.2 Build Validation: Environment setup failed"
LOCATION              = "nue"
