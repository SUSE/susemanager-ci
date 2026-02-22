ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:92:42:01:00"
    name = "controller"
  }
  server_containerized = {
    mac  = "aa:b2:92:42:01:01"
    name = "server"
    image = "sles15sp7o"
    string_registry = true
  }
  proxy_containerized = {
    mac  = "aa:b2:92:42:01:02"
    name = "proxy"
    image = "sles15sp7o"
    string_registry = true
  }
  monitoring_server = {
    mac  = "aa:b2:92:42:01:03"
    name = "monitoring"
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
  sles15sp3_minion = {
    mac  = "aa:b2:92:42:01:11"
    name = "sles15sp3-minion"
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
  centos7_minion = {
    mac  = "aa:b2:92:42:01:17"
    name = "centos7-minion"
  }
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
  alma9_minion = {
    mac  = "aa:b2:92:42:01:22"
    name = "alma9-minion"
  }
  oracle9_minion = {
    mac  = "aa:b2:92:42:01:23"
    name = "oracle9-minion"
  }
  amazon2023_minion = {
    mac  = "aa:b2:92:42:01:24"
    name = "amazon2023-minion"
  }
  liberty9_minion = {
    mac  = "aa:b2:92:42:01:25"
    name = "liberty9-minion"
  }
  ubuntu2204_minion = {
    mac  = "aa:b2:92:42:01:1b"
    name = "ubuntu2204-minion"
  }
  debian12_minion = {
    mac  = "aa:b2:92:42:01:1c"
    name = "debian12-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:92:42:01:1d"
    name = "ubuntu2404-minion"
  }
  opensuse156arm_minion = {
    mac  = "aa:b2:92:42:01:2e"
    name = "opensuse156arm-minion"
  }
  salt_migration_minion = {
    mac  = "aa:b2:92:42:01:2f"
    name = "salt-migration-minion"
  }
  sles15sp5s390_minion = {
    mac  = "02:00:00:42:00:2a"
    name = "sles15sp5s390-minion"
    userid = "S51MINUE"
  }

  # Micro Minions
  slemicro52_minion = {
    mac  = "aa:b2:92:42:01:27"
    name = "slemicro52-minion"
  }
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

  # SSH Minions
  sles12sp5_sshminion = {
    mac  = "aa:b2:92:42:01:30"
    name = "sles12sp5-sshminion"
  }
  sles15sp3_sshminion = {
    mac  = "aa:b2:92:42:01:31"
    name = "sles15sp3-sshminion"
  }
  sles15sp4_sshminion = {
    mac  = "aa:b2:92:42:01:32"
    name = "sles15sp4-sshminion"
  }
  sles15sp5_sshminion = {
    mac  = "aa:b2:92:42:01:33"
    name = "sles15sp5-sshminion"
  }
  sles15sp6_sshminion = {
    mac  = "aa:b2:92:42:01:34"
    name = "sles15sp6-sshminion"
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:92:42:01:35"
    name = "sles15sp7-sshminion"
  }
  centos7_sshminion = {
    mac  = "aa:b2:92:42:01:37"
    name = "centos7-sshminion"
  }
  rocky8_sshminion = {
    mac  = "aa:b2:92:42:01:38"
    name = "rocky8-sshminion"
  }
  alma8_sshminion = {
    mac  = "aa:b2:92:42:01:39"
    name = "alma8-sshminion"
  }
  rocky9_sshminion = {
    mac  = "aa:b2:92:42:01:41"
    name = "rocky9-sshminion"
  }
  alma9_sshminion = {
    mac  = "aa:b2:92:42:01:42"
    name = "alma9-sshminion"
  }
  oracle9_sshminion = {
    mac  = "aa:b2:92:42:01:43"
    name = "oracle9-sshminion"
  }
  amazon2023_sshminion = {
    mac  = "aa:b2:92:42:01:44"
    name = "amazon2023-sshminion"
  }
  liberty9_sshminion = {
    mac  = "aa:b2:92:42:01:45"
    name = "liberty9-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:92:42:01:3b"
    name = "ubuntu2204-sshminion"
  }
  debian12_sshminion = {
    mac  = "aa:b2:92:42:01:3c"
    name = "debian12-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:92:42:01:3d"
    name = "ubuntu2404-sshminion"
  }
  opensuse156arm_sshminion = {
    mac  = "aa:b2:92:42:01:4e"
    name = "opensuse156arm-sshminion"
  }
  sles15sp5s390_sshminion = {
    mac  = "02:00:00:42:00:2b"
    name = "sles15sp5s390-sshminion"
    userid = "S51SSNUE"
  }
  product_version       = "5.1-released"
  name_prefix           = "mlm-bv-51-sles-"
  url_prefix            = "https://ci.suse.de/view/Manager/view/Manager-qe/job/manager-5.1-sles-qe-build-validation"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br1"
    additional_network = "192.168.51.0/24"
    hypervisor         = "suma-10.mgr.suse.de"
  }
  base_arm = {
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "suma-arm.mgr.suse.de"
  }
}
MAIL_SUBJECT          = "Results 5.1 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.1 Build Validation: Environment setup failed"
LOCATION              = "nue"
