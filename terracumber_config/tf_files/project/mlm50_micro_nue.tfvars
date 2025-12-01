ENVIRONMENT_CONFIGURATION = {
  mac = {
    # Core Infrastructure
    controller             = "aa:b2:92:42:01:00"
    server_containerized   = "aa:b2:92:42:01:01"
    proxy_containerized    = "aa:b2:92:42:01:02"

    # Standard Minions
    sles12sp5_minion       = "aa:b2:92:42:01:10"
    sles15sp4_minion       = "aa:b2:92:42:01:12"
  }
  s390 = {
    minion_userid     = "S51MINUE"
    shh_minion_userid = "S51SSNUE"
  }
  server_base_os        = "slemicro55o"
  proxy_base_os         = "slemicro55o"
  product_version       = "4.3-released"
  name_prefix           = "mlm-bv-51micro-"
  url_prefix            = "https://ci.suse.de/view/Manager/view/Manager-qe/job/manager-5.1-micro-qe-build-validation-NUE"
  base_core = {
    pool               = "ssd"
    bridge             = "br1"
    additional_network = "192.168.51.0/24"
    hypervisor         = "suma-10.mgr.suse.de"
  }
}
MAIL_SUBJECT          = "Results 5.1 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.1 Build Validation: Environment setup failed"
LOCATION              = "nue"
