ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:92:05:00:f8"
    name = "controller"
  }
  server = {
    mac   = "aa:b2:92:05:00:f9"
    name  = "server"
  }
  proxy = {
    mac   = "aa:b2:92:05:00:fa"
    name  = "proxy"
  }

  # Minions
  sles15sp4_minion = {
    mac  = "aa:b2:92:05:00:fb"
    name = "sles15sp4-minion"
  }

  # Global Settings
  product_version = "4.3-released"
  name_prefix     = "suma-su-43-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-4.3/job/manager-4.3-qe-sle-update-SLC"
}

BASE_CONFIGURATIONS = {
  base_core = {
    images             = [ "sles15sp4o", "opensuse156o" ]
    pool               = "ssd"
    bridge             = "br0"
    hypervisor         = "riverworld.mgr.slc1.suse.org"
    additional_network = null
  }
}

MAIL_SUBJECT          = "Results 4.3 SLE Update $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 4.3 SLE Update: Environment setup failed"
LOCATION              = "slc1"