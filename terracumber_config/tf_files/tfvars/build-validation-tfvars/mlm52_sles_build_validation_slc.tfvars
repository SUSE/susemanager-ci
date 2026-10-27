ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:92:05:00:00"
    name = "controller"
    memory = 24576
  }
  server_containerized = {
    mac   = "aa:b2:92:05:00:01"
    name  = "server"
    image = "sles15sp7o"
  }
  proxy_containerized = {
    mac   = "aa:b2:92:05:00:02"
    name  = "proxy"
    image = "sles15sp7o"
  }
  monitoring_server = {
    mac  = "aa:b2:92:05:00:03"
    name = "monitoring"
    image = "sles15sp7o"
  }
  sles15sp6_buildhost = {
    mac  = "aa:b2:92:05:00:06"
    name = "sles15sp6-build"
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:92:05:00:07"
    name = "sles15sp7-build"
  }

  # Standard Minions
  sles12sp5_minion = {
    mac  = "aa:b2:92:05:00:10"
    name = "sles12sp5-minion"
  }
  sles15sp4_minion = {
    mac  = "aa:b2:92:05:00:12"
    name = "sles15sp4-minion"
  }
  sles15sp5_minion = {
    mac  = "aa:b2:92:05:00:13"
    name = "sles15sp5-minion"
  }
  sles15sp6_minion = {
    mac  = "aa:b2:92:05:00:14"
    name = "sles15sp6-minion"
  }
  sles15sp7_minion = {
    mac  = "aa:b2:92:05:00:15"
    name = "sles15sp7-minion"
  }
  sles160_minion = {
    mac  = "aa:b2:92:05:00:16"
    name = "sles160-minion"
  }
  alma8_minion = {
    mac  = "aa:b2:92:05:00:19"
    name = "alma8-minion"
  }
  alma9_minion = {
    mac  = "aa:b2:92:05:00:22"
    name = "alma9-minion"
  }
  amazon2023_minion = {
    mac  = "aa:b2:92:05:00:24"
    name = "amazon2023-minion"
  }
  centos7_minion = {
    mac  = "aa:b2:92:05:00:17"
    name = "centos7-minion"
  }
  liberty9_minion = {
    mac  = "aa:b2:92:05:00:25"
    name = "liberty9-minion"
  }
  oracle9_minion = {
    mac  = "aa:b2:92:05:00:23"
    name = "oracle9-minion"
  }
  rocky8_minion = {
    mac  = "aa:b2:92:05:00:18"
    name = "rocky8-minion"
  }
  rocky9_minion = {
    mac  = "aa:b2:92:05:00:21"
    name = "rocky9-minion"
  }
  # alma10, liberty10, oracle10, and rocky 10 cannot run in SLC (no x86_v3)
  openeuler2403_minion = {
    mac  = "aa:b2:92:05:00:20"
    name = "openeuler2403-minion"
  }
  rhel7_minion = {
    mac  = "aa:b2:92:05:00:30"
    name = "rhel7-minion"
  }
  rhel8_minion = {
    mac  = "aa:b2:92:05:00:31"
    name = "rhel8-minion"
  }
  rhel9_minion = {
    mac  = "aa:b2:92:05:00:32"
    name = "rhel9-minion"
  }
  rhel10_minion = {
    mac  = "aa:b2:92:05:00:33"
    name = "rhel10-minion"
  }
  debian13_minion = {
    mac  = "aa:b2:92:05:00:11"
    name = "debian13-minion"
  }
  raspios13_minion = {
    mac  = "aa:b2:92:42:00:0c"
    name = "raspios13-minion"
  }
  ubuntu2204_minion = {
    mac  = "aa:b2:92:05:00:1b"
    name = "ubuntu2204-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:92:05:00:1d"
    name = "ubuntu2404-minion"
  }
  ubuntu2604_minion = {
    mac  = "aa:b2:92:05:00:1c"
    name = "ubuntu2604-minion"
  }
  opensuse161arm_minion = {
    mac  = "aa:b2:92:42:00:0a"
    name = "opensuse161arm-minion"
  }
  opensuse161ppc_minion = {
    mac  = "aa:b2:92:42:00:0e"
    name = "opensuse161ppc-minion"
  }
  sles161_minion = {
    mac  = "aa:b2:92:05:00:35"
    name = "sles161-minion"
  }
  slesforsap15sp5_minion = {
    mac  = "aa:b2:92:05:00:36"
    name = "slesforsap15sp5-minion"
  }
  slesforsap15sp6_minion = {
    mac  = "aa:b2:92:05:00:37"
    name = "slesforsap15sp6-minion"
  }
  slesforsap15sp7_minion = {
    mac  = "aa:b2:92:05:00:38"
    name = "slesforsap15sp7-minion"
  }
  slesforsap160_minion = {
    mac  = "aa:b2:92:05:00:39"
    name = "slesforsap160-minion"
  }
  slesforsap161_minion = {
    mac  = "aa:b2:92:05:00:3a"
    name = "slesforsap161-minion"
  }
  sles15sp5s390_minion = {
    mac    = "02:00:00:02:01:32"
    name   = "sles15sp5s390-minion"
    userid = "M52MISLC"
  }
  salt_migration_minion = {
    mac  = "aa:b2:92:05:00:2f"
    name = "salt-migration-minion"
  }

  # Micro Minions
  slemicro53_minion = {
    mac  = "aa:b2:92:05:00:28"
    name = "slemicro53-minion"
  }
  slemicro54_minion = {
    mac  = "aa:b2:92:05:00:29"
    name = "slemicro54-minion"
  }
  slemicro55_minion = {
    mac  = "aa:b2:92:05:00:2a"
    name = "slemicro55-minion"
  }
  slmicro60_minion = {
    mac  = "aa:b2:92:05:00:2b"
    name = "slmicro60-minion"
  }
  slmicro61_minion = {
    mac  = "aa:b2:92:05:00:2c"
    name = "slmicro61-minion"
  }
  slmicro62_minion = {
    mac  = "aa:b2:92:05:00:2d"
    name = "slmicro62-minion"
  }

  # SSH Minions
  sles12sp5_sshminion = {
    mac  = "aa:b2:92:05:00:40"
    name = "sles12sp5-sshminion"
  }
  sles15sp4_sshminion = {
    mac  = "aa:b2:92:05:00:42"
    name = "sles15sp4-sshminion"
  }
  sles15sp5_sshminion = {
    mac  = "aa:b2:92:05:00:43"
    name = "sles15sp5-sshminion"
  }
  sles15sp6_sshminion = {
    mac  = "aa:b2:92:05:00:44"
    name = "sles15sp6-sshminion"
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:92:05:00:45"
    name = "sles15sp7-sshminion"
  }
  sles160_sshminion = {
    mac  = "aa:b2:92:05:00:46"
    name = "sles160-sshminion"
  }
  alma8_sshminion = {
    mac  = "aa:b2:92:05:00:49"
    name = "alma8-sshminion"
  }
  alma9_sshminion = {
    mac  = "aa:b2:92:05:00:52"
    name = "alma9-sshminion"
  }
  amazon2023_sshminion = {
    mac  = "aa:b2:92:05:00:54"
    name = "amazon2023-sshminion"
  }
  centos7_sshminion = {
    mac  = "aa:b2:92:05:00:47"
    name = "centos7-sshminion"
  }
  liberty9_sshminion = {
    mac  = "aa:b2:92:05:00:55"
    name = "liberty9-sshminion"
  }
  oracle9_sshminion = {
    mac  = "aa:b2:92:05:00:53"
    name = "oracle9-sshminion"
  }
  rocky8_sshminion = {
    mac  = "aa:b2:92:05:00:48"
    name = "rocky8-sshminion"
  }
  rocky9_sshminion = {
    mac  = "aa:b2:92:05:00:51"
    name = "rocky9-sshminion"
  }
  # alma10, liberty10, oracle10, and rocky 10 cannot run in SLC (no x86_v3)
  openeuler2403_sshminion = {
    mac  = "aa:b2:92:05:00:50"
    name = "openeuler2403-sshminion"
  }
  rhel7_sshminion = {
    mac  = "aa:b2:92:05:00:60"
    name = "rhel7-sshminion"
  }
  rhel8_sshminion = {
    mac  = "aa:b2:92:05:00:61"
    name = "rhel8-sshminion"
  }
  rhel9_sshminion = {
    mac  = "aa:b2:92:05:00:62"
    name = "rhel9-sshminion"
  }
  rhel10_sshminion = {
    mac  = "aa:b2:92:05:00:63"
    name = "rhel10-sshminion"
  }
  debian13_sshminion = {
    mac  = "aa:b2:92:05:00:41"
    name = "debian13-sshminion"
  }
  raspios13_sshminion = {
    mac  = "aa:b2:92:42:00:0d"
    name = "raspios13-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:92:05:00:4b"
    name = "ubuntu2204-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:92:05:00:4d"
    name = "ubuntu2404-sshminion"
  }
  ubuntu2604_sshminion = {
    mac  = "aa:b2:92:05:00:4c"
    name = "ubuntu2604-sshminion"
  }
  opensuse161arm_sshminion = {
    mac  = "aa:b2:92:42:00:0b"
    name = "opensuse161arm-sshminion"
  }
  opensuse161ppc_sshminion = {
    mac  = "aa:b2:92:42:00:0f"
    name = "opensuse161ppc-sshminion"
  }
  sles161_sshminion = {
    mac  = "aa:b2:92:05:00:65"
    name = "sles161-sshminion"
  }
  sles15sp5s390_sshminion = {
    mac    = "02:00:00:02:01:33"
    name   = "sles15sp5s390-sshminion"
    userid = "M52SSSLC"
  }

  product_version = "5.2-released"
  name_prefix     = "mlm-bv-52-sles-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-qe/job/manager-5.2-sles-qe-build-validation-BACKUP"
}

BASE_CONFIGURATIONS = {
  base_core = {
    images             = [ "opensuse160o", "sles15sp5o", "sles15sp7o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "caladan.mgr.slc1.suse.org"
  }
  base_old_sle = {
    images             = [ "sles12sp5o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "tatooine.mgr.slc1.suse.org"
  }
  base_rhlike = {
    # alma10, oracle10, and rocky 10 cannot run in SLC (no x86_v3)
    images             = [ "almalinux8o", "almalinux9o", "amazonlinux2023o", "centos7o", "libertylinux9o", "openeuler2403o", "oraclelinux9o", "rocky8o", "rocky9o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "tatooine.mgr.slc1.suse.org"
  }
  base_new_sle = {
    images             = [ "sles15sp4o", "sles15sp5o", "sles15sp6o", "sles15sp7o", "sles160o", "sles161o", "slesforsap160o", "slesforsap161o", "slemicro53-ign", "slemicro54-ign", "slemicro55o", "slmicro60o", "slmicro61o", "slmicro62o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "florina.mgr.slc1.suse.org"
  }
  base_retail = {
    images             = [ "sles15sp6o", "sles15sp7o", "opensuse160o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = "192.168.52.0/24"
    hypervisor         = "terminus.mgr.slc1.suse.org"
  }
  base_deblike = {
    images             = [ "ubuntu2204o", "ubuntu2404o", "ubuntu2604o", "debian13o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "trantor.mgr.slc1.suse.org"
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
LOCATION              = "slc1"
