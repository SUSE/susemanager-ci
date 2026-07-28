ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:04:05:6c"
    name = "controller"
    memory = 24576
  }
  server_containerized = {
    mac   = "aa:b2:93:04:05:6d"
    name  = "server"
    image = "sles15sp7o"
    string_registry = true
  }
  proxy_containerized = {
    mac   = "aa:b2:93:04:05:6e"
    name  = "proxy"
    image = "sles15sp7o"
    string_registry = true
  }
  monitoring_server = {
    mac  = "aa:b2:93:04:05:6f"
    name = "monitoring"
    image = "sles15sp7o"
  }
  sles15sp6_buildhost = {
    mac  = "aa:b2:93:04:05:72"
    name = "sles15sp6-build"
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:93:04:05:73"
    name = "sles15sp7-build"
  }

  # Standard Minions
  sles12sp5_minion = {
    mac  = "aa:b2:93:04:05:7c"
    name = "sles12sp5-minion"
  }
  sles15sp4_minion = {
    mac  = "aa:b2:93:04:05:7e"
    name = "sles15sp4-minion"
  }
  sles15sp5_minion = {
    mac  = "aa:b2:93:04:05:7f"
    name = "sles15sp5-minion"
  }
  sles15sp6_minion = {
    mac  = "aa:b2:93:04:05:80"
    name = "sles15sp6-minion"
  }
  sles15sp7_minion = {
    mac  = "aa:b2:93:04:05:81"
    name = "sles15sp7-minion"
  }
  sles160_minion = {
    mac  = "aa:b2:93:04:05:82"
    name = "sles160-minion"
  }
  alma8_minion = {
    mac  = "aa:b2:93:04:05:85"
    name = "alma8-minion"
  }
  alma9_minion = {
    mac  = "aa:b2:93:04:05:8e"
    name = "alma9-minion"
  }
  amazon2023_minion = {
    mac  = "aa:b2:93:04:05:90"
    name = "amazon2023-minion"
  }
  centos7_minion = {
    mac  = "aa:b2:93:04:05:83"
    name = "centos7-minion"
  }
  liberty9_minion = {
    mac  = "aa:b2:93:04:05:91"
    name = "liberty9-minion"
  }
  oracle9_minion = {
    mac  = "aa:b2:93:04:05:8f"
    name = "oracle9-minion"
  }
  rocky8_minion = {
    mac  = "aa:b2:93:04:05:84"
    name = "rocky8-minion"
  }
  rocky9_minion = {
    mac  = "aa:b2:93:04:05:8d"
    name = "rocky9-minion"
  }
  rocky10_minion = {
    mac  = "aa:b2:93:04:05:8a"
    name = "rocky10-minion"
  }
  alma10_minion = {
    mac  = "aa:b2:93:04:05:86"
    name = "alma10-minion"
  }
  oracle10_minion = {
    mac  = "aa:b2:93:04:05:8b"
    name = "oracle10-minion"
  }
  liberty10_minion = {
    mac  = "aa:b2:93:04:05:92"
    name = "liberty10-minion"
  }
  openeuler2403_minion = {
    mac  = "aa:b2:93:04:05:8c"
    name = "openeuler2403-minion"
  }
  debian13_minion = {
    mac  = "aa:b2:93:04:05:7d"
    name = "debian13-minion"
  }
  raspios13_minion = {
    mac  = "aa:b2:93:04:05:93"
    name = "raspios13-minion"
  }
  ubuntu2204_minion = {
    mac  = "aa:b2:93:04:05:87"
    name = "ubuntu2204-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:93:04:05:89"
    name = "ubuntu2404-minion"
  }
  ubuntu2604_minion = {
    mac  = "aa:b2:93:04:05:88"
    name = "ubuntu2604-minion"
  }
  opensuse160arm_minion = {
    mac  = "aa:b2:92:42:00:10"
    name = "opensuse160arm-minion-slc"
  }
  sles15sp5s390_minion = {
    mac    = "02:00:00:02:01:34"
    name   = "sles15sp5s390-minion"
    userid = "M99MISLC"
  }
  salt_migration_minion = {
    mac  = "aa:b2:93:04:05:9b"
    name = "salt-migration-minion"
  }

  # Micro Minions
  slemicro52_minion = {
    mac  = "aa:b2:93:04:05:93"
    name = "slemicro52-minion"
  }
  slemicro53_minion = {
    mac  = "aa:b2:93:04:05:94"
    name = "slemicro53-minion"
  }
  slemicro54_minion = {
    mac  = "aa:b2:93:04:05:95"
    name = "slemicro54-minion"
  }
  slemicro55_minion = {
    mac  = "aa:b2:93:04:05:96"
    name = "slemicro55-minion"
  }
  slmicro60_minion = {
    mac  = "aa:b2:93:04:05:97"
    name = "slmicro60-minion"
  }
  slmicro61_minion = {
    mac  = "aa:b2:93:04:05:98"
    name = "slmicro61-minion"
  }
  slmicro62_minion = {
    mac  = "aa:b2:93:04:05:99"
    name = "slmicro62-minion"
  }

  # SSH Minions
  sles12sp5_sshminion = {
    mac  = "aa:b2:93:04:05:9c"
    name = "sles12sp5-sshminion"
  }
  sles15sp4_sshminion = {
    mac  = "aa:b2:93:04:05:9e"
    name = "sles15sp4-sshminion"
  }
  sles15sp5_sshminion = {
    mac  = "aa:b2:93:04:05:9f"
    name = "sles15sp5-sshminion"
  }
  sles15sp6_sshminion = {
    mac  = "aa:b2:93:04:05:a0"
    name = "sles15sp6-sshminion"
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:93:04:05:a1"
    name = "sles15sp7-sshminion"
  }
  alma8_sshminion = {
    mac  = "aa:b2:93:04:05:a5"
    name = "alma8-sshminion"
  }
  alma9_sshminion = {
    mac  = "aa:b2:93:04:05:ae"
    name = "alma9-sshminion"
  }
  amazon2023_sshminion = {
    mac  = "aa:b2:93:04:05:b0"
    name = "amazon2023-sshminion"
  }
  centos7_sshminion = {
    mac  = "aa:b2:93:04:05:a3"
    name = "centos7-sshminion"
  }
  liberty9_sshminion = {
    mac  = "aa:b2:93:04:05:b1"
    name = "liberty9-sshminion"
  }
  oracle9_sshminion = {
    mac  = "aa:b2:93:04:05:af"
    name = "oracle9-sshminion"
  }
  rocky8_sshminion = {
    mac  = "aa:b2:93:04:05:a4"
    name = "rocky8-sshminion"
  }
  rocky9_sshminion = {
    mac  = "aa:b2:93:04:05:ad"
    name = "rocky9-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:93:04:05:a7"
    name = "ubuntu2204-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:93:04:05:a9"
    name = "ubuntu2404-sshminion"
  }
  ubuntu2604_sshminion = {
    mac  = "aa:b2:93:04:05:a8"
    name = "ubuntu2604-sshminion"
  }
  opensuse160arm_sshminion = {
    mac  = "aa:b2:92:42:00:11"
    name = "opensuse160arm-sshminion-slc"
  }
  sles15sp5s390_sshminion = {
    mac    = "02:00:00:02:01:35"
    name   = "sles15sp5s390-sshminion"
    userid = "M99SSSLC"
  }

  product_version = "head"
  name_prefix     = "mlm-bv-head-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-Head/job/manager-head-qe-build-validation-BACKUP/"
}

BASE_CONFIGURATIONS = {
  base_core = {
    images             = [ "tumbleweedo", "opensuse156o", "opensuse160o", "sles15sp7o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "giediprime.mgr.slc1.suse.org"
  }
  base_old_sle = {
    images             = [ "sles12sp5o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "cosmopolitan.mgr.slc1.suse.org"
  }
  base_rhlike = {
    images             = [ "almalinux8o", "almalinux9o", "almalinux10o", "amazonlinux2023o", "centos7o", "libertylinux9o", "libertylinux10o", "openeuler2403o", "oraclelinux9o", "oraclelinux10o", "rocky8o", "rocky9o", "rocky10o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "cosmopolitan.mgr.slc1.suse.org"
  }
  base_new_sle = {
    images             = [ "sles15sp4o", "sles15sp5o", "sles15sp6o", "sles15sp7o", "sles160o", "slemicro52-ign", "slemicro53-ign" , "slemicro54-ign", "slemicro55o", "slmicro60o", "slmicro61o", "slmicro62o", "tumbleweedo" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "ginfizz.mgr.slc1.suse.org"
  }
  base_retail = {
    images             = [ "sles15sp6o", "sles15sp7o", "opensuse156o", "opensuse160o", "leapmicro55o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = "192.168.100.0/24"
    hypervisor         = "margarita.mgr.slc1.suse.org"
  }
  base_deblike = {
    images             = [ "ubuntu2204o", "ubuntu2404o", "ubuntu2604", "debian13o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "caipirinha.mgr.slc1.suse.org"
  }
  base_arm = {
    images             = [ "opensuse160armo", "raspios13o" ]
    pool               = "ssd"
    bridge             = "br0"
    additional_network = null
    hypervisor         = "suma-arm.mgr.suse.de"
  }
}

MAIL_SUBJECT          = "Results HEAD Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results HEAD Build Validation: Environment setup failed"
LOCATION              = "slc1"
