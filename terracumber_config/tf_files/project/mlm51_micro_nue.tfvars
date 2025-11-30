ENVIRONMENT_CONFIGURATION = {
  mac = {
    # Core Infrastructure
    controller             = "aa:b2:92:42:01:00"
    server_containerized   = "aa:b2:92:42:01:01"
    proxy_containerized    = "aa:b2:92:42:01:02"
    monitoring_server      = "aa:b2:92:42:01:03"
    sles15sp6_buildhost    = "aa:b2:92:42:01:06"
    sles15sp7_buildhost    = "aa:b2:92:42:01:07"

    # Standard Minions
    sles12sp5_minion       = "aa:b2:92:42:01:10"
    sles15sp3_minion       = "aa:b2:92:42:01:11"
    sles15sp4_minion       = "aa:b2:92:42:01:12"
    sles15sp5_minion       = "aa:b2:92:42:01:13"
    sles15sp6_minion       = "aa:b2:92:42:01:14"
    sles15sp7_minion       = "aa:b2:92:42:01:15"
    centos7_minion         = "aa:b2:92:42:01:17"
    rocky8_minion          = "aa:b2:92:42:01:18"
    alma8_minion           = "aa:b2:92:42:01:19"
    rocky9_minion          = "aa:b2:92:42:01:21"
    alma9_minion           = "aa:b2:92:42:01:22"
    oracle9_minion         = "aa:b2:92:42:01:23"
    amazon2023_minion      = "aa:b2:92:42:01:24"
    liberty9_minion        = "aa:b2:92:42:01:25"
    ubuntu2204_minion      = "aa:b2:92:42:01:1b"
    debian12_minion        = "aa:b2:92:42:01:1c"
    ubuntu2404_minion      = "aa:b2:92:42:01:1d"
    opensuse156arm_minion  = "aa:b2:92:42:01:2e"
    salt_migration_minion  = "aa:b2:92:42:01:2f"
    sles15sp5s390_minion   = "02:00:00:42:00:2a"

    # Micro Minions
    slemicro51_minion      = "aa:b2:92:42:01:26"
    slemicro52_minion      = "aa:b2:92:42:01:27"
    slemicro53_minion      = "aa:b2:92:42:01:28"
    slemicro54_minion      = "aa:b2:92:42:01:29"
    slemicro55_minion      = "aa:b2:92:42:01:2a"
    slmicro60_minion       = "aa:b2:92:42:01:2b"
    slmicro61_minion       = "aa:b2:92:42:01:2c"

    # SSH Minions
    sles12sp5_sshminion      = "aa:b2:92:42:01:30"
    sles15sp3_sshminion      = "aa:b2:92:42:01:31"
    sles15sp4_sshminion      = "aa:b2:92:42:01:32"
    sles15sp5_sshminion      = "aa:b2:92:42:01:33"
    sles15sp6_sshminion      = "aa:b2:92:42:01:34"
    sles15sp7_sshminion      = "aa:b2:92:42:01:35"
    centos7_sshminion        = "aa:b2:92:42:01:37"
    rocky8_sshminion         = "aa:b2:92:42:01:38"
    alma8_sshminion          = "aa:b2:92:42:01:39"
    rocky9_sshminion         = "aa:b2:92:42:01:41"
    alma9_sshminion          = "aa:b2:92:42:01:42"
    oracle9_sshminion        = "aa:b2:92:42:01:43"
    amazon2023_sshminion     = "aa:b2:92:42:01:44"
    liberty9_sshminion       = "aa:b2:92:42:01:45"
    ubuntu2204_sshminion     = "aa:b2:92:42:01:3b"
    debian12_sshminion       = "aa:b2:92:42:01:3c"
    ubuntu2404_sshminion     = "aa:b2:92:42:01:3d"
    opensuse156arm_sshminion = "aa:b2:92:42:01:4e"
    sles15sp5s390_sshminion  = "02:00:00:42:00:2b"
  }
  s390 = {
    minion_userid     = "S51MINUE"
    shh_minion_userid = "S51SSNUE"
  }
  product_version       = "5.1-released"
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
