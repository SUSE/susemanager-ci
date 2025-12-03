ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:92:42:00:a0"
    name = "controller"
  }
  # SUMA 4.3 uses VM-based Server, not containerized
  server = {
    mac  = "aa:b2:92:42:00:a1"
    name = "server"
  }
  # SUMA 4.3 uses VM-based Proxy, not containerized
  proxy = {
    mac  = "aa:b2:92:42:00:a2"
    name = "proxy"
  }
  monitoring_server = {
    mac  = "aa:b2:92:42:00:a3"
    name = "monitoring"
  }
  sles15sp6_buildhost = {
    mac  = "aa:b2:92:42:00:a6"
    name = "sles15sp6-build"
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:92:42:00:a7"
    name = "sles15sp7-build"
  }

  # Traditional Clients (Specific to 4.3/4.x workflows)
  sles12sp5_client = {
    mac  = "aa:b2:92:42:00:a8"
    name = "sles12sp5-client"
  }
  sles15sp3_client = {
    mac  = "aa:b2:92:42:00:a9"
    name = "sles15sp3-client"
  }
  sles15sp4_client = {
    mac  = "aa:b2:92:42:00:aa"
    name = "sles15sp4-client"
  }
  sles15sp5_client = {
    mac  = "aa:b2:92:42:00:ab"
    name = "sles15sp5-client"
  }
  sles15sp6_client = {
    mac  = "aa:b2:92:42:00:ac"
    name = "sles15sp6-client"
  }
  sles15sp7_client = {
    mac  = "aa:b2:92:42:00:ad"
    name = "sles15sp7-client"
  }
  centos7_client = {
    mac  = "aa:b2:92:42:00:af"
    name = "centos7-client"
  }

  # Standard Minions
  sles12sp5_minion = {
    mac  = "aa:b2:92:42:00:b0"
    name = "sles12sp5-minion"
  }
  sles15sp3_minion = {
    mac  = "aa:b2:92:42:00:b1"
    name = "sles15sp3-minion"
  }
  sles15sp4_minion = {
    mac  = "aa:b2:92:42:00:b2"
    name = "sles15sp4-minion"
  }
  sles15sp5_minion = {
    mac  = "aa:b2:92:42:00:b3"
    name = "sles15sp5-minion"
  }
  sles15sp6_minion = {
    mac  = "aa:b2:92:42:00:b4"
    name = "sles15sp6-minion"
  }
  sles15sp7_minion = {
    mac  = "aa:b2:92:42:00:b5"
    name = "sles15sp7-minion"
  }
  centos7_minion = {
    mac  = "aa:b2:92:42:00:b7"
    name = "centos7-minion"
  }
  rocky8_minion = {
    mac  = "aa:b2:92:42:00:b8"
    name = "rocky8-minion"
  }
  alma8_minion = {
    mac  = "aa:b2:92:42:00:b9"
    name = "alma8-minion"
  }
  rocky9_minion = {
    mac  = "aa:b2:92:42:00:c1"
    name = "rocky9-minion"
  }
  alma9_minion = {
    mac  = "aa:b2:92:42:00:c2"
    name = "alma9-minion"
  }
  oracle9_minion = {
    mac  = "aa:b2:92:42:00:c3"
    name = "oracle9-minion"
  }
  liberty9_minion = {
    mac  = "aa:b2:92:42:00:c5"
    name = "liberty9-minion"
  }
  ubuntu2204_minion = {
    mac  = "aa:b2:92:42:00:bb"
    name = "ubuntu2204-minion"
  }
  debian12_minion = {
    mac  = "aa:b2:92:42:00:bc"
    name = "debian12-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:92:42:00:bd"
    name = "ubuntu2404-minion"
  }
  opensuse156arm_minion = {
    mac  = "aa:b2:92:42:00:ce"
    name = "opensuse156arm-minion"
  }
  salt_migration_minion = {
    mac  = "aa:b2:92:42:00:cf"
    name = "salt-migration-minion"
  }
  sles15sp5s390_minion = {
    mac    = "02:00:00:42:00:26"
    name   = "sles15sp5s390-minion"
    userid = "S43MINUE"
  }

  # Micro Minions
  slemicro51_minion = {
    mac  = "aa:b2:92:42:00:c6"
    name = "slemicro51-minion"
  }
  slemicro52_minion = {
    mac  = "aa:b2:92:42:00:c7"
    name = "slemicro52-minion"
  }
  slemicro53_minion = {
    mac  = "aa:b2:92:42:00:c8"
    name = "slemicro53-minion"
  }
  slemicro54_minion = {
    mac  = "aa:b2:92:42:00:c9"
    name = "slemicro54-minion"
  }
  slemicro55_minion = {
    mac  = "aa:b2:92:42:00:ca"
    name = "slemicro55-minion"
  }
  slmicro60_minion = {
    mac  = "aa:b2:92:42:00:cb"
    name = "slmicro60-minion"
  }
  slmicro61_minion = {
    mac  = "aa:b2:92:42:00:cc"
    name = "slmicro61-minion"
  }

  # SSH Minions
  sles12sp5_sshminion = {
    mac  = "aa:b2:92:42:00:d0"
    name = "sles12sp5-sshminion"
  }
  sles15sp3_sshminion = {
    mac  = "aa:b2:92:42:00:d1"
    name = "sles15sp3-sshminion"
  }
  sles15sp4_sshminion = {
    mac  = "aa:b2:92:42:00:d2"
    name = "sles15sp4-sshminion"
  }
  sles15sp5_sshminion = {
    mac  = "aa:b2:92:42:00:d3"
    name = "sles15sp5-sshminion"
  }
  sles15sp6_sshminion = {
    mac  = "aa:b2:92:42:00:d4"
    name = "sles15sp6-sshminion"
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:92:42:00:d5"
    name = "sles15sp7-sshminion"
  }
  centos7_sshminion = {
    mac  = "aa:b2:92:42:00:d7"
    name = "centos7-sshminion"
  }
  rocky8_sshminion = {
    mac  = "aa:b2:92:42:00:d8"
    name = "rocky8-sshminion"
  }
  alma8_sshminion = {
    mac  = "aa:b2:92:42:00:d9"
    name = "alma8-sshminion"
  }
  rocky9_sshminion = {
    mac  = "aa:b2:92:42:00:e1"
    name = "rocky9-sshminion"
  }
  alma9_sshminion = {
    mac  = "aa:b2:92:42:00:e2"
    name = "alma9-sshminion"
  }
  oracle9_sshminion = {
    mac  = "aa:b2:92:42:00:e3"
    name = "oracle9-sshminion"
  }
  liberty9_sshminion = {
    mac  = "aa:b2:92:42:00:e5"
    name = "liberty9-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:92:42:00:db"
    name = "ubuntu2204-sshminion"
  }
  debian12_sshminion = {
    mac  = "aa:b2:92:42:00:dc"
    name = "debian12-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:92:42:00:dd"
    name = "ubuntu2404-sshminion"
  }
  opensuse156arm_sshminion = {
    mac  = "aa:b2:92:42:00:ee"
    name = "opensuse156arm-sshminion"
  }
  sles15sp5s390_sshminion = {
    mac    = "02:00:00:42:00:27"
    name   = "sles15sp5s390-sshminion"
    userid = "S43SSNUE"
  }

  product_version = "4.3-released"
  name_prefix     = "suma-bv-43-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-4.3/job/manager-4.3-qe-build-validation"

  base_core = {
    pool               = "ssd"
    bridge             = "br0"
    hypervisor         = "suma-07.mgr.suse.de"
    additional_network = "192.168.43.0/24"
  }
}
MAIL_SUBJECT          = "Results 4.3 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 4.3 Build Validation: Environment setup failed"
LOCATION              = "nue"