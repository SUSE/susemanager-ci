ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:01:01:8c"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:93:01:01:8d"
    name  = "server"
    image = "slmicro61o"
    string_registry = true
  }
  proxy_containerized = {
    mac   = "aa:b2:93:01:01:8e"
    name  = "proxy"
    image = "slmicro61o"
    string_registry = true
  }

  # Standard Minions
  sles15sp7_minion = {
    mac  = "aa:b2:93:01:01:90"
    name = "suse-minion"
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:93:01:01:91"
    name = "suse-sshminion"
  }

  # Standard Minions
  rocky8_minion = {
    mac  = "aa:b2:93:01:01:92"
    name = "rhlike-minion"
  }

  # Standard Minions
  ubuntu2404_minion = {
    mac  = "aa:b2:93:01:01:93"
    name = "deblike-minion"
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:93:01:01:94"
    name = "build-host"
  }
  product_version = "5.1-nighly"
  name_prefix     = "maxime-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-5.1/job/maxime"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "mnoel_disks"
    bridge             = "br0"
    hypervisor         = "suma-05.mgr.suse.de"
    additional_network = "192.168.17.0/24"
  }
}
MAIL_SUBJECT          = "Results 5.1 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.1 Build Validation: Environment setup failed"
LOCATION              = "nue"
