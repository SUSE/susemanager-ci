ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:01:02:80"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:93:01:02:81"
    name  = "server"
    image = "slmicro61o"
  }
  proxy_containerized = {
    mac   = "aa:b2:93:01:02:82"
    name  = "proxy"
    image = "slmicro61o"
  }
  monitoring_server = {
    mac  = "aa:b2:93:01:02:83"
    name = "monitoring"
  }
  sles15sp6_buildhost = {
    mac  = "aa:b2:93:01:02:86"
    name = "sles15sp6-build"
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:93:01:02:87"
    name = "sles15sp7-build"
  }

  # Standard Minions
  sles12sp5_minion = {
    mac  = "aa:b2:93:01:02:90"
    name = "sles12sp5-minion"
  }
  sles15sp3_minion = {
    mac  = "aa:b2:93:01:02:91"
    name = "sles15sp3-minion"
  }
  sles15sp4_minion = {
    mac  = "aa:b2:93:01:02:92"
    name = "sles15sp4-minion"
  }
  sles15sp5_minion = {
    mac  = "aa:b2:93:01:02:93"
    name = "sles15sp5-minion"
  }
  sles15sp6_minion = {
    mac  = "aa:b2:93:01:02:94"
    name = "sles15sp6-minion"
  }
  sles15sp7_minion = {
    mac  = "aa:b2:93:01:02:95"
    name = "sles15sp7-minion"
  }
  centos7_minion = {
    mac  = "aa:b2:93:01:02:97"
    name = "centos7-minion"
  }
  rocky8_minion = {
    mac  = "aa:b2:93:01:02:98"
    name = "rocky8-minion"
  }
  alma8_minion = {
    mac  = "aa:b2:93:01:02:99"
    name = "alma8-minion"
  }
  rocky9_minion = {
    mac  = "aa:b2:93:01:02:a1"
    name = "rocky9-minion"
  }
  alma9_minion = {
    mac  = "aa:b2:93:01:02:a2"
    name = "alma9-minion"
  }
  oracle9_minion = {
    mac  = "aa:b2:93:01:02:a3"
    name = "oracle9-minion"
  }
  amazon2023_minion = {
    mac  = "aa:b2:93:01:02:a4"
    name = "amazon2023-minion"
  }
  liberty9_minion = {
    mac  = "aa:b2:93:01:02:a5"
    name = "liberty9-minion"
  }
  ubuntu2204_minion = {
    mac  = "aa:b2:93:01:02:9b"
    name = "ubuntu2204-minion"
  }
  debian12_minion = {
    mac  = "aa:b2:93:01:02:9c"
    name = "debian12-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:93:01:02:9d"
    name = "ubuntu2404-minion"
  }
  opensuse156arm_minion = {
    mac  = "aa:b2:93:01:02:ae"
    name = "opensuse156arm-minion"
  }
  salt_migration_minion = {
    mac  = "aa:b2:93:01:02:af"
    name = "salt-migration-minion"
  }
  sles15sp5s390_minion = {
    mac    = "02:00:00:42:00:2e"
    name   = "sles15sp5s390-minion"
    userid = "W51MINUE"
  }

  # Micro Minions
  slemicro51_minion = {
    mac  = "aa:b2:93:01:02:a6"
    name = "slemicro51-minion"
  }
  slemicro52_minion = {
    mac  = "aa:b2:93:01:02:a7"
    name = "slemicro52-minion"
  }
  slemicro53_minion = {
    mac  = "aa:b2:93:01:02:a8"
    name = "slemicro53-minion"
  }
  slemicro54_minion = {
    mac  = "aa:b2:93:01:02:a9"
    name = "slemicro54-minion"
  }
  slemicro55_minion = {
    mac  = "aa:b2:93:01:02:aa"
    name = "slemicro55-minion"
  }
  slmicro60_minion = {
    mac  = "aa:b2:93:01:02:ab"
    name = "slmicro60-minion"
  }
  slmicro61_minion = {
    mac  = "aa:b2:93:01:02:ac"
    name = "slmicro61-minion"
  }

  # SSH Minions
  sles12sp5_sshminion = {
    mac  = "aa:b2:93:01:02:b0"
    name = "sles12sp5-sshminion"
  }
  sles15sp3_sshminion = {
    mac  = "aa:b2:93:01:02:b1"
    name = "sles15sp3-sshminion"
  }
  sles15sp4_sshminion = {
    mac  = "aa:b2:93:01:02:b2"
    name = "sles15sp4-sshminion"
  }
  sles15sp5_sshminion = {
    mac  = "aa:b2:93:01:02:b3"
    name = "sles15sp5-sshminion"
  }
  sles15sp6_sshminion = {
    mac  = "aa:b2:93:01:02:b4"
    name = "sles15sp6-sshminion"
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:93:01:02:b5"
    name = "sles15sp7-sshminion"
  }
  centos7_sshminion = {
    mac  = "aa:b2:93:01:02:b7"
    name = "centos7-sshminion"
  }
  rocky8_sshminion = {
    mac  = "aa:b2:93:01:02:b8"
    name = "rocky8-sshminion"
  }
  alma8_sshminion = {
    mac  = "aa:b2:93:01:02:b9"
    name = "alma8-sshminion"
  }
  rocky9_sshminion = {
    mac  = "aa:b2:93:01:02:c1"
    name = "rocky9-sshminion"
  }
  alma9_sshminion = {
    mac  = "aa:b2:93:01:02:c2"
    name = "alma9-sshminion"
  }
  oracle9_sshminion = {
    mac  = "aa:b2:93:01:02:c3"
    name = "oracle9-sshminion"
  }
  amazon2023_sshminion = {
    mac  = "aa:b2:93:01:02:c4"
    name = "amazon2023-sshminion"
  }
  liberty9_sshminion = {
    mac  = "aa:b2:93:01:02:c5"
    name = "liberty9-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:93:01:02:bb"
    name = "ubuntu2204-sshminion"
  }
  debian12_sshminion = {
    mac  = "aa:b2:93:01:02:bc"
    name = "debian12-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:93:01:02:bd"
    name = "ubuntu2404-sshminion"
  }
  opensuse156arm_sshminion = {
    mac  = "aa:b2:93:01:02:ce"
    name = "opensuse156arm-sshminion"
  }
  sles15sp5s390_sshminion = {
    mac    = "02:00:00:42:00:2f"
    name   = "sles15sp5s390-sshminion"
    userid = "W51SSNUE"
  }
  product_version = "5.1-released"
  name_prefix     = "suma-continuous-bv-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-qe/job/manager-qe-build-validation-continuous-NUE"
  base_core = {
    pool               = "ssd"
    bridge             = "br1"
    hypervisor         = "suma-11.mgr.suse.de"
    additional_network = "192.168.100.0/24"
  }
}
MAIL_SUBJECT          = "Results Continuous Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results Continuous Build Validation: Environment setup failed"
LOCATION              = "nue"
