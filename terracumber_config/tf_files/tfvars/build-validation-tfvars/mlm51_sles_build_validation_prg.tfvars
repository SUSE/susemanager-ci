ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac    = "aa:b2:92:42:01:00"
    name   = "controller"
    memory = 24576
  }
  server_containerized = {
    mac             = "aa:b2:92:42:01:01"
    name            = "server"
    image           = "sles15sp7o"
  }
  proxy_containerized = {
    mac             = "aa:b2:92:42:01:02"
    name            = "proxy"
    image           = "sles15sp7o"
  }
  monitoring_server = {
    mac   = "aa:b2:92:42:01:03"
    name  = "monitoring"
    image = "sles15sp7o"
  }
  sles15sp6_buildhost = {
    mac  = "aa:b2:92:42:01:06"
    name = "sles15sp6-build"
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:92:42:01:07"
    name = "sles15sp7-build"
  }

  # Standard Minions
  sles12sp5_minion = {
    mac  = "aa:b2:92:42:01:10"
    name = "sles12sp5-minion"
  }
  sles15sp4_minion = {
    mac  = "aa:b2:92:42:01:12"
    name = "sles15sp4-minion"
  }
  sles15sp5_minion = {
    mac  = "aa:b2:92:42:01:13"
    name = "sles15sp5-minion"
  }
  sles15sp6_minion = {
    mac  = "aa:b2:92:42:01:14"
    name = "sles15sp6-minion"
  }
  sles15sp7_minion = {
    mac  = "aa:b2:92:42:01:15"
    name = "sles15sp7-minion"
  }
  sles160_minion = {
    mac  = "aa:b2:92:42:01:16"
    name = "sles160-minion"
  }
  centos7_minion = {
    mac  = "aa:b2:92:42:01:17"
    name = "centos7-minion"
  }
  # We forgot to automate amazon 2
  rocky8_minion = {
    mac  = "aa:b2:92:42:01:18"
    name = "rocky8-minion"
  }
  alma8_minion = {
    mac  = "aa:b2:92:42:01:19"
    name = "alma8-minion"
  }
  rocky9_minion = {
    mac  = "aa:b2:92:42:01:21"
    name = "rocky9-minion"
  }
  rocky10_minion = {
    mac  = "aa:b2:92:42:01:1e"
    name = "rocky10-minion"
  }
  alma9_minion = {
    mac  = "aa:b2:92:42:01:22"
    name = "alma9-minion"
  }
  alma10_minion = {
    mac  = "aa:b2:92:42:01:1a"
    name = "alma10-minion"
  }
  oracle9_minion = {
    mac  = "aa:b2:92:42:01:23"
    name = "oracle9-minion"
  }
  oracle10_minion = {
    mac  = "aa:b2:92:42:01:1f"
    name = "oracle10-minion"
  }
  amazon2023_minion = {
    mac  = "aa:b2:92:42:01:24"
    name = "amazon2023-minion"
  }
  liberty9_minion = {
    mac  = "aa:b2:92:42:01:25"
    name = "liberty9-minion"
  }
  rhel7_minion = {
    mac  = "aa:b2:92:42:01:30"
    name = "rhel7-minion"
  }
  rhel8_minion = {
    mac  = "aa:b2:92:42:01:31"
    name = "rhel8-minion"
  }
  rhel9_minion = {
    mac  = "aa:b2:92:42:01:32"
    name = "rhel9-minion"
  }
  rhel10_minion = {
    mac  = "aa:b2:92:42:01:33"
    name = "rhel10-minion"
  }
  ubuntu2204_minion = {
    mac  = "aa:b2:92:42:01:1b"
    name = "ubuntu2204-minion"
  }
  debian13_minion = {
    mac  = "aa:b2:92:42:01:11"
    name = "debian13-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:92:42:01:1d"
    name = "ubuntu2404-minion"
  }
  ubuntu2604_minion = {
    mac  = "aa:b2:92:42:01:1c"
    name = "ubuntu2604-minion"
  }
  opensuse161arm_minion = {
    mac  = "aa:b2:92:42:01:2e"
    name = "opensuse161arm-minion"
  }
  opensuse161ppc_minion = {
    mac  = "aa:b2:92:42:01:34"
    name = "opensuse161ppc-minion"
  }
  salt_migration_minion = {
    mac  = "aa:b2:92:42:01:2f"
    name = "salt-migration-minion"
  }
  sles15sp5s390_minion = {
    mac    = "02:00:00:42:00:2a"
    name   = "sles15sp5s390-minion"
    userid = "M51MIPRG"
  }

  # Micro Minions
  slemicro53_minion = {
    mac  = "aa:b2:92:42:01:28"
    name = "slemicro53-minion"
  }
  slemicro54_minion = {
    mac  = "aa:b2:92:42:01:29"
    name = "slemicro54-minion"
  }
  slemicro55_minion = {
    mac  = "aa:b2:92:42:01:2a"
    name = "slemicro55-minion"
  }
  slmicro60_minion = {
    mac  = "aa:b2:92:42:01:2b"
    name = "slmicro60-minion"
  }
  slmicro61_minion = {
    mac  = "aa:b2:92:42:01:2c"
    name = "slmicro61-minion"
  }
  slmicro62_minion = {
    mac  = "aa:b2:92:42:01:2d"
    name = "slmicro62-minion"
  }

  # SSH Minions
  sles12sp5_sshminion = {
    mac  = "aa:b2:92:42:01:40"
    name = "sles12sp5-sshminion"
  }
  sles15sp4_sshminion = {
    mac  = "aa:b2:92:42:01:42"
    name = "sles15sp4-sshminion"
  }
  sles15sp5_sshminion = {
    mac  = "aa:b2:92:42:01:43"
    name = "sles15sp5-sshminion"
  }
  sles15sp6_sshminion = {
    mac  = "aa:b2:92:42:01:44"
    name = "sles15sp6-sshminion"
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:92:42:01:45"
    name = "sles15sp7-sshminion"
  }
  sles160_sshminion = {
    mac  = "aa:b2:92:42:01:46"
    name = "sles160-sshminion"
  }
  centos7_sshminion = {
    mac  = "aa:b2:92:42:01:47"
    name = "centos7-sshminion"
  }
  # We forgot to automate amazon 2
  rocky8_sshminion = {
    mac  = "aa:b2:92:42:01:48"
    name = "rocky8-sshminion"
  }
  alma8_sshminion = {
    mac  = "aa:b2:92:42:01:49"
    name = "alma8-sshminion"
  }
  rocky9_sshminion = {
    mac  = "aa:b2:92:42:01:51"
    name = "rocky9-sshminion"
  }
  rocky10_sshminion = {
    mac  = "aa:b2:92:42:01:4e"
    name = "rocky10-sshminion"
  }
  alma9_sshminion = {
    mac  = "aa:b2:92:42:01:52"
    name = "alma9-sshminion"
  }
  alma10_sshminion = {
    mac  = "aa:b2:92:42:01:4a"
    name = "alma10-sshminion"
  }
  oracle9_sshminion = {
    mac  = "aa:b2:92:42:01:53"
    name = "oracle9-sshminion"
  }
  oracle10_sshminion = {
    mac  = "aa:b2:92:42:01:4f"
    name = "oracle10-sshminion"
  }
  amazon2023_sshminion = {
    mac  = "aa:b2:92:42:01:54"
    name = "amazon2023-sshminion"
  }
  liberty9_sshminion = {
    mac  = "aa:b2:92:42:01:55"
    name = "liberty9-sshminion"
  }
  rhel7_sshminion = {
    mac  = "aa:b2:92:42:01:60"
    name = "rhel7-sshminion"
  }
  rhel8_sshminion = {
    mac  = "aa:b2:92:42:01:61"
    name = "rhel8-sshminion"
  }
  rhel9_sshminion = {
    mac  = "aa:b2:92:42:01:62"
    name = "rhel9-sshminion"
  }
  rhel10_sshminion = {
    mac  = "aa:b2:92:42:01:63"
    name = "rhel10-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:92:42:01:4b"
    name = "ubuntu2204-sshminion"
  }
  debian13_sshminion = {
    mac  = "aa:b2:92:42:01:41"
    name = "debian13-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:92:42:01:4d"
    name = "ubuntu2404-sshminion"
  }
  ubuntu2604_sshminion = {
    mac  = "aa:b2:92:42:01:4c"
    name = "ubuntu2604-sshminion"
  }
  opensuse161arm_sshminion = {
    mac  = "aa:b2:92:42:01:5e"
    name = "opensuse161arm-sshminion"
  }
  opensuse161ppc_sshminion = {
    mac  = "aa:b2:92:42:01:64"
    name = "opensuse161ppc-sshminion"
  }
  sles15sp5s390_sshminion = {
    mac    = "02:00:00:42:00:2b"
    name   = "sles15sp5s390-sshminion"
    userid = "M51SSPRG"
  }
  product_version = "5.1-released"
  name_prefix     = "mlm-bv-51-sles-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-qe/job/manager-5.1-sles-qe-build-validation"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br1"
    additional_network = "192.168.51.0/24"
    hypervisor         = "suma-10.mgr.suse.de"
    autostart          = true
  }
  base_arm = {
    images             = [ "opensuse161armo" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "suma-arm.mgr.suse.de"
    autostart          = true
  }
  base_ppc = {
    images             = [ "opensuse161ppco" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "suma-ppc.mgr.suse.de"
    autostart          = true
  }
}
MAIL_SUBJECT          = "Results 5.1 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.1 Build Validation: Environment setup failed"
LOCATION              = "prg2"
