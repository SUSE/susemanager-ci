ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:92:42:00:40"
    name = "controller"
    memory = 24576
  }
  server_containerized = {
    mac  = "aa:b2:92:42:00:41"
    name = "server"
    image = "sles15sp7o"
  }
  proxy_containerized = {
    mac  = "aa:b2:92:42:00:42"
    name = "proxy"
    image = "sles15sp7o"
  }
  monitoring_server = {
    mac  = "aa:b2:92:42:00:43"
    name = "monitoring"
    image = "sles15sp7o"
  }
  sles15sp6_buildhost = {
    mac  = "aa:b2:92:42:00:46"
    name = "sles15sp6-build"
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:92:42:00:47"
    name = "sles15sp7-build"
  }

  # Standard Minions
  sles12sp5_minion = {
    mac  = "aa:b2:92:42:00:50"
    name = "sles12sp5-minion"
  }
  sles15sp4_minion = {
    mac  = "aa:b2:92:42:00:52"
    name = "sles15sp4-minion"
  }
  sles15sp5_minion = {
    mac  = "aa:b2:92:42:00:53"
    name = "sles15sp5-minion"
  }
  sles15sp6_minion = {
    mac  = "aa:b2:92:42:00:54"
    name = "sles15sp6-minion"
  }
  sles15sp7_minion = {
    mac  = "aa:b2:92:42:00:55"
    name = "sles15sp7-minion"
  }
  sles160_minion = {
    mac  = "aa:b2:92:42:00:56"
    name = "sles160-minion"
  }
  centos7_minion = {
    mac  = "aa:b2:92:42:00:57"
    name = "centos7-minion"
  }
  rocky8_minion = {
    mac  = "aa:b2:92:42:00:58"
    name = "rocky8-minion"
  }
  alma8_minion = {
    mac  = "aa:b2:92:42:00:59"
    name = "alma8-minion"
  }
  rocky9_minion = {
    mac  = "aa:b2:92:42:00:61"
    name = "rocky9-minion"
  }
  rocky10_minion = {
    mac  = "aa:b2:92:42:00:5e"
    name = "rocky10-minion"
  }
  alma9_minion = {
    mac  = "aa:b2:92:42:00:62"
    name = "alma9-minion"
  }
  alma10_minion = {
    mac  = "aa:b2:92:42:00:5a"
    name = "alma10-minion"
  }
  oracle9_minion = {
    mac  = "aa:b2:92:42:00:63"
    name = "oracle9-minion"
  }
  oracle10_minion = {
    mac  = "aa:b2:92:42:00:5f"
    name = "oracle10-minion"
  }
  amazon2023_minion = {
    mac  = "aa:b2:92:42:00:64"
    name = "amazon2023-minion"
  }
  liberty9_minion = {
    mac  = "aa:b2:92:42:00:65"
    name = "liberty9-minion"
  }
  liberty10_minion = {
    mac  = "aa:b2:92:42:00:66"
    name = "liberty10-minion"
  }
  openeuler2403_minion = {
    mac  = "aa:b2:92:42:00:60"
    name = "openeuler2403-minion"
  }
  rhel7_minion = {
    mac  = "aa:b2:92:42:00:70"
    name = "rhel7-minion"
  }
  rhel8_minion = {
    mac  = "aa:b2:92:42:00:71"
    name = "rhel8-minion"
  }
  rhel9_minion = {
    mac  = "aa:b2:92:42:00:72"
    name = "rhel9-minion"
  }
  rhel10_minion = {
    mac  = "aa:b2:92:42:00:73"
    name = "rhel10-minion"
  }
  debian13_minion = {
    mac  = "aa:b2:92:42:00:51"
    name = "debian13-minion"
  }
  raspios13_minion = {
    mac  = "aa:b2:92:42:00:67"
    name = "raspios13-minion"
  }
  ubuntu2204_minion = {
    mac  = "aa:b2:92:42:00:5b"
    name = "ubuntu2204-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:92:42:00:5d"
    name = "ubuntu2404-minion"
  }
  ubuntu2604_minion = {
    mac  = "aa:b2:92:42:00:5c"
    name = "ubuntu2604-minion"
  }
  opensuse161arm_minion = {
    mac  = "aa:b2:92:42:00:6e"
    name = "opensuse161arm-minion"
  }
  opensuse161ppc_minion = {
    mac  = "aa:b2:92:42:00:74"
    name = "opensuse161ppc-minion"
  }
  salt_migration_minion = {
    mac  = "aa:b2:92:42:00:6f"
    name = "salt-migration-minion"
  }
  sles15sp5s390_minion = {
    mac  = "02:00:00:42:00:24"
    name = "sles15sp5s390-minion"
    userid = "M52MIPRG"
  }

  # Micro Minions
  slemicro53_minion = {
    mac  = "aa:b2:92:42:00:68"
    name = "slemicro53-minion"
  }
  slemicro54_minion = {
    mac  = "aa:b2:92:42:00:69"
    name = "slemicro54-minion"
  }
  slemicro55_minion = {
    mac  = "aa:b2:92:42:00:6a"
    name = "slemicro55-minion"
  }
  slmicro60_minion = {
    mac  = "aa:b2:92:42:00:6b"
    name = "slmicro60-minion"
  }
  slmicro61_minion = {
    mac  = "aa:b2:92:42:00:6c"
    name = "slmicro61-minion"
  }
  slmicro62_minion = {
    mac  = "aa:b2:92:42:00:6d"
    name = "slmicro62-minion"
  }

  # SSH Minions
  sles12sp5_sshminion = {
    mac  = "aa:b2:92:42:00:80"
    name = "sles12sp5-sshminion"
  }
  sles15sp4_sshminion = {
    mac  = "aa:b2:92:42:00:82"
    name = "sles15sp4-sshminion"
  }
  sles15sp5_sshminion = {
    mac  = "aa:b2:92:42:00:83"
    name = "sles15sp5-sshminion"
  }
  sles15sp6_sshminion = {
    mac  = "aa:b2:92:42:00:84"
    name = "sles15sp6-sshminion"
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:92:42:00:85"
    name = "sles15sp7-sshminion"
  }
  sles160_sshminion = {
    mac  = "aa:b2:92:42:00:86"
    name = "sles160-sshminion"
  }
  centos7_sshminion = {
    mac  = "aa:b2:92:42:00:87"
    name = "centos7-sshminion"
  }
  rocky8_sshminion = {
    mac  = "aa:b2:92:42:00:88"
    name = "rocky8-sshminion"
  }
  alma8_sshminion = {
    mac  = "aa:b2:92:42:00:89"
    name = "alma8-sshminion"
  }
  rocky9_sshminion = {
    mac  = "aa:b2:92:42:00:91"
    name = "rocky9-sshminion"
  }
  rocky10_sshminion = {
    mac  = "aa:b2:92:42:00:8e"
    name = "rocky10-sshminion"
  }
  alma9_sshminion = {
    mac  = "aa:b2:92:42:00:92"
    name = "alma9-sshminion"
  }
  alma10_sshminion = {
    mac  = "aa:b2:92:42:00:8a"
    name = "alma10-sshminion"
  }
  oracle9_sshminion = {
    mac  = "aa:b2:92:42:00:93"
    name = "oracle9-sshminion"
  }
  oracle10_sshminion = {
    mac  = "aa:b2:92:42:00:8f"
    name = "oracle10-sshminion"
  }
  amazon2023_sshminion = {
    mac  = "aa:b2:92:42:00:94"
    name = "amazon2023-sshminion"
  }
  liberty9_sshminion = {
    mac  = "aa:b2:92:42:00:95"
    name = "liberty9-sshminion"
  }
  liberty10_sshminion = {
    mac  = "aa:b2:92:42:00:96"
    name = "liberty10-sshminion"
  }
  openeuler2403_sshminion = {
    mac  = "aa:b2:92:42:00:90"
    name = "openeuler2403-sshminion"
  }
  rhel7_sshminion = {
    mac  = "aa:b2:92:42:00:a0"
    name = "rhel7-sshminion"
  }
  rhel8_sshminion = {
    mac  = "aa:b2:92:42:00:a1"
    name = "rhel8-sshminion"
  }
  rhel9_sshminion = {
    mac  = "aa:b2:92:42:00:a2"
    name = "rhel9-sshminion"
  }
  rhel10_sshminion = {
    mac  = "aa:b2:92:42:00:a3"
    name = "rhel10-sshminion"
  }
  debian13_sshminion = {
    mac  = "aa:b2:92:42:00:81"
    name = "debian13-sshminion"
  }
  raspios13_sshminion = {
    mac  = "aa:b2:92:42:00:97"
    name = "raspios13-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:92:42:00:8b"
    name = "ubuntu2204-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:92:42:00:8d"
    name = "ubuntu2404-sshminion"
  }
  ubuntu2604_sshminion = {
    mac  = "aa:b2:92:42:00:8c"
    name = "ubuntu2604-sshminion"
  }
  opensuse161arm_sshminion = {
    mac  = "aa:b2:92:42:00:9e"
    name = "opensuse161arm-sshminion"
  }
  opensuse161ppc_sshminion = {
    mac  = "aa:b2:92:42:00:a4"
    name = "opensuse161ppc-sshminion"
  }
  sles15sp5s390_sshminion = {
    mac  = "02:00:00:42:00:25"
    name = "sles15sp5s390-sshminion"
    userid = "M52SSPRG"
  }
  product_version      = "5.2-released"
  name_prefix          = "mlm-bv-52-sles-"
  url_prefix           = "https://ci.suse.de/view/Manager/view/Manager-qe/job/manager-5.2-sles-qe-build-validation"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br0"
    additional_network = "192.168.52.0/24"
    hypervisor         = "suma-14.mgr.suse.de"
  }
  base_arm = {
    images             = [ "opensuse161armo", "raspios13o" ]
    pool               = "ssd"
    bridge             = "br0"
    additional_network = null
    hypervisor         = "suma-arm.mgr.suse.de"
  }
  base_ppc = {
    images             = [ "opensuse161ppco" ]
    pool               = "ssd"
    bridge             = "br0"
    additional_network = null
    hypervisor         = "suma-ppc.mgr.suse.de"
  }
}
MAIL_SUBJECT          = "Results 5.2 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.2 Build Validation: Environment setup failed"
LOCATION              = "prg2"
