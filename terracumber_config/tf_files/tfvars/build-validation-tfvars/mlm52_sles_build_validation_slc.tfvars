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
    string_registry = false

  }
  proxy_containerized = {
    mac   = "aa:b2:92:05:00:02"
    name  = "proxy"
    image = "sles15sp7o"
    string_registry = false
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
  rocky10_minion = {
    mac  = "aa:b2:92:05:00:1e"
    name = "rocky10-minion"
  }
  alma10_minion = {
    mac  = "aa:b2:92:05:00:1a"
    name = "alma10-minion"
  }
  oracle10_minion = {
    mac  = "aa:b2:92:05:00:1f"
    name = "oracle10-minion"
  }
  liberty10_minion = {
    mac  = "aa:b2:92:05:00:26"
    name = "liberty10-minion"
  }
  openeuler2403_minion = {
    mac  = "aa:b2:92:05:00:20"
    name = "openeuler2403-minion"
  }
  rhel7_minion = {
    mac  = "aa:b2:92:05:00:08"
    name = "rhel7-minion"
  }
  rhel8_minion = {
    mac  = "aa:b2:92:05:00:09"
    name = "rhel8-minion"
  }
  rhel9_minion = {
    mac  = "aa:b2:92:05:00:0a"
    name = "rhel9-minion"
  }
  rhel10_minion = {
    mac  = "aa:b2:92:05:00:0b"
    name = "rhel10-minion"
  }
  debian13_minion = {
    mac  = "aa:b2:92:05:00:11"
    name = "debian13-minion"
  }
  raspios13_minion = {
    mac  = "aa:b2:92:05:00:27"
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
  opensuse160arm_minion = {
    mac  = "aa:b2:92:42:00:0a"
    name = "opensuse160arm-minion"
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
  slemicro52_minion = {
    mac  = "aa:b2:92:05:00:27"
    name = "slemicro52-minion"
  }
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
    mac  = "aa:b2:92:05:00:30"
    name = "sles12sp5-sshminion"
  }
  sles15sp4_sshminion = {
    mac  = "aa:b2:92:05:00:32"
    name = "sles15sp4-sshminion"
  }
  sles15sp5_sshminion = {
    mac  = "aa:b2:92:05:00:33"
    name = "sles15sp5-sshminion"
  }
  sles15sp6_sshminion = {
    mac  = "aa:b2:92:05:00:34"
    name = "sles15sp6-sshminion"
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:92:05:00:35"
    name = "sles15sp7-sshminion"
  }
  alma8_sshminion = {
    mac  = "aa:b2:92:05:00:39"
    name = "alma8-sshminion"
  }
  alma9_sshminion = {
    mac  = "aa:b2:92:05:00:42"
    name = "alma9-sshminion"
  }
  amazon2023_sshminion = {
    mac  = "aa:b2:92:05:00:44"
    name = "amazon2023-sshminion"
  }
  centos7_sshminion = {
    mac  = "aa:b2:92:05:00:37"
    name = "centos7-sshminion"
  }
  liberty9_sshminion = {
    mac  = "aa:b2:92:05:00:45"
    name = "liberty9-sshminion"
  }
  oracle9_sshminion = {
    mac  = "aa:b2:92:05:00:43"
    name = "oracle9-sshminion"
  }
  rocky8_sshminion = {
    mac  = "aa:b2:92:05:00:38"
    name = "rocky8-sshminion"
  }
  rocky9_sshminion = {
    mac  = "aa:b2:92:05:00:41"
    name = "rocky9-sshminion"
  }
  rhel7_sshminion = {
    mac  = "aa:b2:92:05:00:0c"
    name = "rhel7-sshminion"
  }
  rhel8_sshminion = {
    mac  = "aa:b2:92:05:00:0d"
    name = "rhel8-sshminion"
  }
  rhel9_sshminion = {
    mac  = "aa:b2:92:05:00:0e"
    name = "rhel9-sshminion"
  }
  rhel10_sshminion = {
    mac  = "aa:b2:92:05:00:0f"
    name = "rhel10-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:92:05:00:3b"
    name = "ubuntu2204-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:92:05:00:3d"
    name = "ubuntu2404-sshminion"
  }
  ubuntu2604_sshminion = {
    mac  = "aa:b2:92:05:00:3c"
    name = "ubuntu2604-sshminion"
  }
  opensuse160arm_sshminion = {
    mac  = "aa:b2:92:42:00:0b"
    name = "opensuse160arm-sshminion"
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
    images             = [ "sles15sp5o", "sles15sp7o", "opensuse156o", "opensuse160o" ]
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
    images             = [ "almalinux8o", "almalinux9o", "almalinux10o", "amazonlinux2023o", "centos7o", "libertylinux9o", "libertylinux10o", "openeuler2403o", "oraclelinux9o", "oraclelinux10o", "rocky8o", "rocky9o", "rocky10o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "tatooine.mgr.slc1.suse.org" # Share base_old_sle hypervisor
  }
  base_new_sle = {
    images             = [ "sles15sp4o", "sles15sp5o", "sles15sp6o", "sles15sp7o", "sles160o", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "slemicro55o", "slmicro60o", "slmicro61o", "slmicro62o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "florina.mgr.slc1.suse.org"
  }
  base_retail = {
    images             = [ "sles15sp6o","sles15sp7o", "opensuse156o", "opensuse160o" ]
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
    images             = [ "opensuse160armo", "raspios13o" ]
    pool               = "ssd"
    bridge             = "br0"
    additional_network = null
    hypervisor         = "suma-arm.mgr.suse.de"
  }
}
MAIL_SUBJECT          = "Results 5.2 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.2 Build Validation: Environment setup failed"
LOCATION              = "slc1"
