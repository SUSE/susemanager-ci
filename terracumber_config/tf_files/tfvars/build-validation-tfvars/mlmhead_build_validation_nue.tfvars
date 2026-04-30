ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac    = "aa:b2:93:02:01:a0"
    name   = "controller"
    memory = 24576
  }
  server_containerized = {
    mac             = "aa:b2:93:02:01:a1"
    name            = "server"
    image           = "sles15sp7o"
    string_registry = true
  }
  proxy_containerized = {
    mac             = "aa:b2:93:02:01:a2"
    name            = "proxy"
    image           = "sles15sp7o"
    string_registry = true
  }
  monitoring_server = {
    mac   = "aa:b2:93:02:01:a3"
    name  = "monitoring"
    image = "sles15sp7o"
  }
  sles15sp6_buildhost = {
    mac  = "aa:b2:93:02:01:a6"
    name = "sles15sp6-build"
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:93:02:01:a7"
    name = "sles15sp7-build"
  }

  # Standard Minions
  sles12sp5_minion = {
    mac  = "aa:b2:93:02:01:b0"
    name = "sles12sp5-minion"
  }
  sles15sp4_minion = {
    mac  = "aa:b2:93:02:01:b2"
    name = "sles15sp4-minion"
  }
  sles15sp5_minion = {
    mac  = "aa:b2:93:02:01:b3"
    name = "sles15sp5-minion"
  }
  sles15sp6_minion = {
    mac  = "aa:b2:93:02:01:b4"
    name = "sles15sp6-minion"
  }
  sles15sp7_minion = {
    mac  = "aa:b2:93:02:01:b5"
    name = "sles15sp7-minion"
  }
  sles160_minion = {
    mac  = "aa:b2:93:02:01:b6"
    name = "sles160-minion"
  }
  centos7_minion = {
    mac  = "aa:b2:93:02:01:b7"
    name = "centos7-minion"
  }
  rocky8_minion = {
    mac  = "aa:b2:93:02:01:b8"
    name = "rocky8-minion"
  }
  alma8_minion = {
    mac  = "aa:b2:93:02:01:b9"
    name = "alma8-minion"
  }
  rocky9_minion = {
    mac  = "aa:b2:93:02:01:c1"
    name = "rocky9-minion"
  }
  rocky10_minion = {
    mac  = "aa:b2:93:02:01:be"
    name = "rocky10-minion"
  }
  alma9_minion = {
    mac  = "aa:b2:93:02:01:c2"
    name = "alma9-minion"
  }
  alma10_minion = {
    mac  = "aa:b2:93:02:01:ba"
    name = "alma10-minion"
  }
  oracle9_minion = {
    mac  = "aa:b2:93:02:01:c3"
    name = "oracle9-minion"
  }
  oracle10_minion = {
    mac  = "aa:b2:93:02:01:bf"
    name = "oracle10-minion"
  }
  amazon2023_minion = {
    mac  = "aa:b2:93:02:01:c4"
    name = "amazon2023-minion"
  }
  liberty9_minion = {
    mac  = "aa:b2:93:02:01:c5"
    name = "liberty9-minion"
  }
  ubuntu2204_minion = {
    mac  = "aa:b2:93:02:01:bb"
    name = "ubuntu2204-minion"
  }
  debian12_minion = {
    mac  = "aa:b2:93:02:01:bc"
    name = "debian12-minion"
  }
  debian13_minion = {
    mac  = "aa:b2:93:02:01:b1"
    name = "debian13-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:93:02:01:bd"
    name = "ubuntu2404-minion"
  }
  opensuse160arm_minion = {
    mac  = "aa:b2:93:02:01:ce"
    name = "opensuse160arm-minion"
  }
  salt_migration_minion = {
    mac  = "aa:b2:93:02:01:cf"
    name = "salt-migration-minion"
  }
  sles15sp5s390_minion = {
    mac    = "02:00:00:42:00:2c"
    name   = "sles15sp5s390-minion"
    userid = "M99MIPRG"
  }

  # Micro Minions
  slemicro52_minion = {
    mac  = "aa:b2:93:02:01:c7"
    name = "slemicro52-minion"
  }
  slemicro53_minion = {
    mac  = "aa:b2:93:02:01:c8"
    name = "slemicro53-minion"
  }
  slemicro54_minion = {
    mac  = "aa:b2:93:02:01:c9"
    name = "slemicro54-minion"
  }
  slemicro55_minion = {
    mac  = "aa:b2:93:02:01:ca"
    name = "slemicro55-minion"
  }
  slmicro60_minion = {
    mac  = "aa:b2:93:02:01:cb"
    name = "slmicro60-minion"
  }
  slmicro61_minion = {
    mac  = "aa:b2:93:02:01:cc"
    name = "slmicro61-minion"
  }
  slmicro62_minion = {
    mac  = "aa:b2:93:02:01:cd"
    name = "slmicro62-minion"
  }

  # SSH Minions
  sles12sp5_sshminion = {
    mac  = "aa:b2:93:02:01:d0"
    name = "sles12sp5-sshminion"
  }
  sles15sp4_sshminion = {
    mac  = "aa:b2:93:02:01:d2"
    name = "sles15sp4-sshminion"
  }
  sles15sp5_sshminion = {
    mac  = "aa:b2:93:02:01:d3"
    name = "sles15sp5-sshminion"
  }
  sles15sp6_sshminion = {
    mac  = "aa:b2:93:02:01:d4"
    name = "sles15sp6-sshminion"
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:93:02:01:d5"
    name = "sles15sp7-sshminion"
  }
  sles160_sshminion = {
    mac  = "aa:b2:93:02:01:d6"
    name = "sles160-sshminion"
  }
  centos7_sshminion = {
    mac  = "aa:b2:93:02:01:d7"
    name = "centos7-sshminion"
  }
  rocky8_sshminion = {
    mac  = "aa:b2:93:02:01:d8"
    name = "rocky8-sshminion"
  }
  alma8_sshminion = {
    mac  = "aa:b2:93:02:01:d9"
    name = "alma8-sshminion"
  }
  rocky9_sshminion = {
    mac  = "aa:b2:93:02:01:e1"
    name = "rocky9-sshminion"
  }
  rocky10_sshminion = {
    mac  = "aa:b2:93:02:01:de"
    name = "rocky10-sshminion"
  }
  alma9_sshminion = {
    mac  = "aa:b2:93:02:01:e2"
    name = "alma9-sshminion"
  }
  alma10_sshminion = {
    mac  = "aa:b2:93:02:01:da"
    name = "alma10-sshminion"
  }
  oracle9_sshminion = {
    mac  = "aa:b2:93:02:01:e3"
    name = "oracle9-sshminion"
  }
  oracle10_sshminion = {
    mac  = "aa:b2:93:02:01:df"
    name = "oracle10-sshminion"
  }
  amazon2023_sshminion = {
    mac  = "aa:b2:93:02:01:e4"
    name = "amazon2023-sshminion"
  }
  liberty9_sshminion = {
    mac  = "aa:b2:93:02:01:e5"
    name = "liberty9-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:93:02:01:db"
    name = "ubuntu2204-sshminion"
  }
  debian12_sshminion = {
    mac  = "aa:b2:93:02:01:dc"
    name = "debian12-sshminion"
  }
  debian13_sshminion = {
    mac  = "aa:b2:93:02:01:d1"
    name = "debian13-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:93:02:01:dd"
    name = "ubuntu2404-sshminion"
  }
  opensuse160arm_sshminion = {
    mac  = "aa:b2:93:02:01:ee"
    name = "opensuse160arm-sshminion"
  }
  sles15sp5s390_sshminion = {
    mac    = "02:00:00:42:00:2d"
    name   = "sles15sp5s390-sshminion"
    userid = "M99SSPRG"
  }
  product_version = "head"
  name_prefix     = "mlm-bv-head-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Uyuni/job/manager-head-qe-build-validation"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br0"
    additional_network = "192.168.100.0/24"
    hypervisor         = "suma-12.mgr.suse.de"
  }
  base_arm = {
    pool               = "ssd"
    bridge             = "br0"
    additional_network = null
    hypervisor         = "suma-arm.mgr.suse.de"
  }
}
MAIL_SUBJECT          = "Results Uyuni Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results Uyuni Build Validation: Environment setup failed"
LOCATION              = "nue"
