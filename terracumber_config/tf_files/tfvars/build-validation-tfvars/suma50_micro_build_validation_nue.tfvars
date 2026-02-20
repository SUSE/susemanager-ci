ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:92:42:00:50"
    name = "controller"
  }
  server_containerized = {
    mac             = "aa:b2:92:42:00:51"
    name            = "server"
    image           = "slemicro55o"
    string_registry = false
  }
  proxy_containerized = {
    mac             = "aa:b2:92:42:00:52"
    name            = "proxy"
    image           = "slemicro55o"
    string_registry = false
  }
  monitoring_server = {
    mac  = "aa:b2:92:42:00:53"
    name = "monitoring"
  }
  sles15sp6_buildhost = {
    mac  = "aa:b2:92:42:00:56"
    name = "sles15sp6-build"
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:92:42:00:57"
    name = "sles15sp7-build"
  }

  # Standard Minions
  sles12sp5_minion = {
    mac  = "aa:b2:92:42:00:60"
    name = "sles12sp5-minion"
  }
  sles15sp3_minion = {
    mac  = "aa:b2:92:42:00:61"
    name = "sles15sp3-minion"
  }
  sles15sp4_minion = {
    mac  = "aa:b2:92:42:00:62"
    name = "sles15sp4-minion"
  }
  sles15sp5_minion = {
    mac  = "aa:b2:92:42:00:63"
    name = "sles15sp5-minion"
  }
  sles15sp6_minion = {
    mac  = "aa:b2:92:42:00:64"
    name = "sles15sp6-minion"
  }
  sles15sp7_minion = {
    mac  = "aa:b2:92:42:00:65"
    name = "sles15sp7-minion"
  }
  centos7_minion = {
    mac  = "aa:b2:92:42:00:67"
    name = "centos7-minion"
  }
  rocky8_minion = {
    mac  = "aa:b2:92:42:00:68"
    name = "rocky8-minion"
  }
  alma8_minion = {
    mac  = "aa:b2:92:42:00:69"
    name = "alma8-minion"
  }
  rocky9_minion = {
    mac  = "aa:b2:92:42:00:71"
    name = "rocky9-minion"
  }
  alma9_minion = {
    mac  = "aa:b2:92:42:00:72"
    name = "alma9-minion"
  }
  oracle9_minion = {
    mac  = "aa:b2:92:42:00:73"
    name = "oracle9-minion"
  }
  liberty9_minion = {
    mac  = "aa:b2:92:42:00:75"
    name = "liberty9-minion"
  }
  ubuntu2204_minion = {
    mac  = "aa:b2:92:42:00:6b"
    name = "ubuntu2204-minion"
  }
  debian12_minion = {
    mac  = "aa:b2:92:42:00:6c"
    name = "debian12-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:92:42:00:6d"
    name = "ubuntu2404-minion"
  }
  opensuse156arm_minion = {
    mac  = "aa:b2:92:42:00:7e"
    name = "opensuse156arm-minion"
  }
  salt_migration_minion = {
    mac  = "aa:b2:92:42:00:7f"
    name = "salt-migration-minion"
  }
  sles15sp5s390_minion = {
    mac    = "02:00:00:42:00:28"
    name   = "sles15sp5s390-minion"
    userid = "S50MINUE"
  }

  # Micro Minions
  slemicro52_minion = {
    mac  = "aa:b2:92:42:00:77"
    name = "slemicro52-minion"
  }
  slemicro53_minion = {
    mac  = "aa:b2:92:42:00:78"
    name = "slemicro53-minion"
  }
  slemicro54_minion = {
    mac  = "aa:b2:92:42:00:79"
    name = "slemicro54-minion"
  }
  slemicro55_minion = {
    mac  = "aa:b2:92:42:00:7a"
    name = "slemicro55-minion"
  }
  slmicro60_minion = {
    mac  = "aa:b2:92:42:00:7b"
    name = "slmicro60-minion"
  }
  slmicro61_minion = {
    mac  = "aa:b2:92:42:00:7c"
    name = "slmicro61-minion"
  }

  # SSH Minions
  sles12sp5_sshminion = {
    mac  = "aa:b2:92:42:00:80"
    name = "sles12sp5-sshminion"
  }
  sles15sp3_sshminion = {
    mac  = "aa:b2:92:42:00:81"
    name = "sles15sp3-sshminion"
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
  alma9_sshminion = {
    mac  = "aa:b2:92:42:00:92"
    name = "alma9-sshminion"
  }
  oracle9_sshminion = {
    mac  = "aa:b2:92:42:00:93"
    name = "oracle9-sshminion"
  }
  liberty9_sshminion = {
    mac  = "aa:b2:92:42:00:95"
    name = "liberty9-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:92:42:00:8b"
    name = "ubuntu2204-sshminion"
  }
  debian12_sshminion = {
    mac  = "aa:b2:92:42:00:8c"
    name = "debian12-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:92:42:00:8d"
    name = "ubuntu2404-sshminion"
  }
  opensuse156arm_sshminion = {
    mac  = "aa:b2:92:42:00:9e"
    name = "opensuse156arm-sshminion"
  }
  sles15sp5s390_sshminion = {
    mac    = "02:00:00:42:00:29"
    name   = "sles15sp5s390-sshminion"
    userid = "S50SSNUE"
  }
  # Note: Amazon Linux 2023 is not present in SUMA 5.0
  product_version = "5.0-released"
  name_prefix     = "suma-bv-50-micro-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-qe/job/manager-5.0-micro-qe-build-validation"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br0"
    additional_network = "192.168.50.0/24"
    hypervisor         = "suma-06.mgr.suse.de"
  }
  base_arm = {
    pool               = "ssd"
    bridge             = "br0"
    additional_network = null
    hypervisor         = "suma-arm.mgr.suse.de"
  }
}
MAIL_SUBJECT          = "Results 5.0 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results HEAD Build Validation: Environment setup failed"
LOCATION              = "nue"
