ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:92:42:01:50"
    name = "controller"
  }
  server_containerized = {
    mac  = "aa:b2:92:42:01:51"
    name = "server"
    image = "sles15sp7o"
    string_registry = true
  }
  proxy_containerized = {
    mac  = "aa:b2:92:42:01:52"
    name = "proxy"
    image = "sles15sp7o"
    string_registry = true
  }
  monitoring_server = {
    mac  = "aa:b2:92:42:01:53"
    name = "monitoring"
    image = "sles15sp7o"
  }
  sles15sp6_buildhost = {
    mac  = "aa:b2:92:42:01:56"
    name = "sles15sp6-build"
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:92:42:01:57"
    name = "sles15sp7-build"
  }

  # Standard Minions
  sles12sp5_minion = {
    mac  = "aa:b2:92:42:01:60"
    name = "sles12sp5-minion"
  }
  sles15sp4_minion = {
    mac  = "aa:b2:92:42:01:62"
    name = "sles15sp4-minion"
  }
  sles15sp5_minion = {
    mac  = "aa:b2:92:42:01:63"
    name = "sles15sp5-minion"
  }
  sles15sp6_minion = {
    mac  = "aa:b2:92:42:01:64"
    name = "sles15sp6-minion"
  }
  sles15sp7_minion = {
    mac  = "aa:b2:92:42:01:65"
    name = "sles15sp7-minion"
  }
  sle160_minion = {
    mac  = "aa:b2:92:42:01:66"
    name = "sles160-minion"
  }
  centos7_minion = {
    mac  = "aa:b2:92:42:01:67"
    name = "centos7-minion"
  }
  rocky8_minion = {
    mac  = "aa:b2:92:42:01:68"
    name = "rocky8-minion"
  }
  alma8_minion = {
    mac  = "aa:b2:92:42:01:69"
    name = "alma8-minion"
  }
  rocky9_minion = {
    mac  = "aa:b2:92:42:01:71"
    name = "rocky9-minion"
  }
  rocky10_minion = {
    mac  = "aa:b2:92:42:01:6e"
    name = "rocky10-minion"
  }
  alma9_minion = {
    mac  = "aa:b2:92:42:01:72"
    name = "alma9-minion"
  }
  alma10_minion = {
    mac  = "aa:b2:92:42:01:6a"
    name = "alma10-minion"
  }
  oracle9_minion = {
    mac  = "aa:b2:92:42:01:73"
    name = "oracle9-minion"
  }
  oracle10_minion = {
    mac  = "aa:b2:92:42:01:6f"
    name = "oracle10-minion"
  }
  amazon2023_minion = {
    mac  = "aa:b2:92:42:01:74"
    name = "amazon2023-minion"
  }
  liberty9_minion = {
    mac  = "aa:b2:92:42:01:75"
    name = "liberty9-minion"
  }
  liberty10_minion = {
    mac  = "aa:b2:92:42:01:76"
    name = "liberty10-minion"
  }
  openeuler2403_minion = {
    mac  = "aa:b2:92:42:01:70"
    name = "openeuler2403-minion"
  }
  debian13_minion = {
    mac  = "aa:b2:92:42:01:61"
    name = "debian13-minion"
  }
  raspios13_minion = {
    mac  = "aa:b2:92:42:01:77"
    name = "raspios13-minion"
  }
  ubuntu2204_minion = {
    mac  = "aa:b2:92:42:01:6b"
    name = "ubuntu2204-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:92:42:01:6d"
    name = "ubuntu2404-minion"
  }
  ubuntu2604_minion = {
    mac  = "aa:b2:92:42:01:6c"
    name = "ubuntu2404-minion"
  }
  opensuse160arm_minion = {
    mac  = "aa:b2:92:42:01:7e"
    name = "opensuse160arm-minion"
  }
  salt_migration_minion = {
    mac  = "aa:b2:92:42:01:7f"
    name = "salt-migration-minion"
  }
  sles15sp5s390_minion = {
    mac  = "02:00:00:42:00:24"
    name = "sles15sp5s390-minion"
    userid = "M52MIPRG"
  }

  # Micro Minions
  slemicro53_minion = {
    mac  = "aa:b2:92:42:01:78"
    name = "slemicro53-minion"
  }
  slemicro54_minion = {
    mac  = "aa:b2:92:42:01:79"
    name = "slemicro54-minion"
  }
  slemicro55_minion = {
    mac  = "aa:b2:92:42:01:7a"
    name = "slemicro55-minion"
  }
  slmicro60_minion = {
    mac  = "aa:b2:92:42:01:7b"
    name = "slmicro60-minion"
  }
  slmicro61_minion = {
    mac  = "aa:b2:92:42:01:7c"
    name = "slmicro61-minion"
  }
  slmicro62_minion = {
    mac  = "aa:b2:92:42:01:7d"
    name = "slmicro62-minion"
  }

  # SSH Minions
  sles12sp5_sshminion = {
    mac  = "aa:b2:92:42:01:80"
    name = "sles12sp5-sshminion"
  }
  sles15sp4_sshminion = {
    mac  = "aa:b2:92:42:01:82"
    name = "sles15sp4-sshminion"
  }
  sles15sp5_sshminion = {
    mac  = "aa:b2:92:42:01:83"
    name = "sles15sp5-sshminion"
  }
  sles15sp6_sshminion = {
    mac  = "aa:b2:92:42:01:84"
    name = "sles15sp6-sshminion"
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:92:42:01:85"
    name = "sles15sp7-sshminion"
  }
  sle160_sshminion = {
    mac  = "aa:b2:92:42:01:86"
    name = "sles160-sshminion"
  }
  centos7_sshminion = {
    mac  = "aa:b2:92:42:01:87"
    name = "centos7-sshminion"
  }
  rocky8_sshminion = {
    mac  = "aa:b2:92:42:01:88"
    name = "rocky8-sshminion"
  }
  alma8_sshminion = {
    mac  = "aa:b2:92:42:01:89"
    name = "alma8-sshminion"
  }
  rocky9_sshminion = {
    mac  = "aa:b2:92:42:01:91"
    name = "rocky9-sshminion"
  }
  rocky10_sshminion = {
    mac  = "aa:b2:92:42:01:8e"
    name = "rocky10-sshminion"
  }
  alma9_sshminion = {
    mac  = "aa:b2:92:42:01:92"
    name = "alma9-sshminion"
  }
  alma10_sshminion = {
    mac  = "aa:b2:92:42:01:8a"
    name = "alma10-sshminion"
  }
  oracle9_sshminion = {
    mac  = "aa:b2:92:42:01:93"
    name = "oracle9-sshminion"
  }
  oracle10_sshminion = {
    mac  = "aa:b2:92:42:01:8f"
    name = "oracle10-sshminion"
  }
  amazon2023_sshminion = {
    mac  = "aa:b2:92:42:01:94"
    name = "amazon2023-sshminion"
  }
  liberty9_sshminion = {
    mac  = "aa:b2:92:42:01:95"
    name = "liberty9-sshminion"
  }
  liberty10_sshminion = {
    mac  = "aa:b2:92:42:01:96"
    name = "liberty10-sshminion"
  }
  openeuler2403_sshminion = {
    mac  = "aa:b2:92:42:01:90"
    name = "openeuler2403-sshminion"
  }
  debian13_sshminion = {
    mac  = "aa:b2:92:42:01:81"
    name = "debian13-sshminion"
  }
  raspios13_sshminion = {
    mac  = "aa:b2:92:42:01:97"
    name = "raspios13-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:92:42:01:8b"
    name = "ubuntu2204-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:92:42:01:8d"
    name = "ubuntu2404-sshminion"
  }
  ubuntu2604_sshminion = {
    mac  = "aa:b2:92:42:01:8c"
    name = "ubuntu2604-sshminion"
  }
  opensuse160arm_sshminion = {
    mac  = "aa:b2:92:42:01:9e"
    name = "opensuse160arm-sshminion"
  }
  sles15sp5s390_sshminion = {
    mac  = "02:00:00:42:00:25"
    name = "sles15sp5s390-sshminion"
    userid = "M52SSPRG"
  }
  # TODO: use final value
  product_version       = "head-staging"
  # product_version     = "5.2-released"
  name_prefix           = "mlm-bv-52-sles-"
  url_prefix            = "https://ci.suse.de/view/Manager/view/Manager-qe/job/manager-5.2-sles-qe-build-validation"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br1"
    additional_network = "192.168.52.0/24"
    # Move as soon as we have a new hypervisor:
    hypervisor         = "suma-10.mgr.suse.de"
  }
  base_arm = {
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "suma-arm.mgr.suse.de"
  }
}
MAIL_SUBJECT          = "Results 5.2 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.2 Build Validation: Environment setup failed"
LOCATION              = "nue"
