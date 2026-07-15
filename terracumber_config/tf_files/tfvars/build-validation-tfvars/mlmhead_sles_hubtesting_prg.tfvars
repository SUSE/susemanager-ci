ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:01:01:c0"
    name = "controller"
  }
  server_containerized = {
    mac                 = "aa:b2:93:01:01:c1"
    name                = "hub"
    image               = "slmicro62o"
    string_registry     = true
    deploy_hub_api      = true
    skip_server_install = false
  }
  server2_containerized = {
    mac                 = "aa:b2:93:01:01:c2"
    name                = "prh1"
    image               = "slmicro62o"
    string_registry     = true
    use_mirror          = false
    deploy_hub_api      = false
    skip_server_install = true
  }
  server3_containerized = {
    mac                 = "aa:b2:93:01:01:c3"
    name                = "prh2"
    image               = "slmicro62o"
    string_registry     = true
    use_mirror          = false
    deploy_hub_api      = false
    skip_server_install = true
  }
  proxy_containerized = {
    mac   = "aa:b2:93:01:01:c4"
    name  = "proxy"
    image = "slmicro62o"
    string_registry = true
  }
  proxy2_containerized = {
    mac   = "aa:b2:93:01:01:c5"
    name  = "proxy2"
    image = "sles15sp7o"
    string_registry = true
  }
  proxy3_containerized = {
    mac   = "aa:b2:93:01:01:c6"
    name  = "proxy3"
    image = "slmicro62o"
    string_registry = true
  }

  # Standard Minions
  sles15sp7_minion = {
    mac  = "aa:b2:93:01:01:c7"
    name = "sles15sp7-minion"
  }
  slmicro62_minion = {
    mac  = "aa:b2:93:01:01:c8"
    name = "slmicro62-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:93:01:01:c9"
    name = "ubuntu2404-minion"
  }
  rocky10_minion = {
    mac  = "aa:b2:93:01:01:ca"
    name = "rocky10-minion"
  }
  monitoring_server = {
    mac  = "aa:b2:93:01:01:cb"
    name = "monitoring"
    image = "sles15sp7o"
  }

  product_version      = "5.2-nightly"
  name_prefix          = "mlm-testhub-"
  url_prefix           = "https://jenkins.mgr.suse.de/job/manager-qe-test-hub-acceptance-tests"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br0"
    hypervisor         = "cthulhu.mgr.suse.de"
    additional_network = null
    images             = ["sles15sp7o", "opensuse160o", "ubuntu2404o", "rocky10o", "slmicro62o"]
  }
}
MAIL_SUBJECT          = "Results 5.2 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.2 Build Validation: Environment setup failed"
LOCATION              = "nue"
