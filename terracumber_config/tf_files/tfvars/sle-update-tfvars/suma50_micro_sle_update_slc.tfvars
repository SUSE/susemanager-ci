ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:92:05:00:fc"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:92:05:00:fd"
    name  = "server"
    image = "slemicro55o"
    string_registry = false
  }
  proxy_containerized = {
    mac   = "aa:b2:92:05:00:fe"
    name  = "proxy"
    image = "slemicro55o"
    string_registry = false
  }

  # Standard Minions
  sles15sp6_minion = {
    mac  = "aa:b2:92:05:00:ff"
    name = "sles15sp6-minion"
  }

  product_version = "5.0-released"
  name_prefix     = "suma-su-50micro-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-5.0/job/manager-5.0-micro-qe-sle-update-SLC"
}

BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br0"
    hypervisor         = "riverworld.mgr.slc1.suse.org"
    additional_network = null
    images             = [ "sles15sp6o", "opensuse156o", "slemicro55o" ]
  }
}
MAIL_SUBJECT          = "Results 5.0 SLE Update $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.0 SLE Update: Environment setup failed"
LOCATION              = "slc1"