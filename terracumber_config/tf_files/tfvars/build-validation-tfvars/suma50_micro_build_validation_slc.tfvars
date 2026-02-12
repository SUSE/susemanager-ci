ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:92:05:00:00"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:92:05:00:01"
    name  = "server"
    image = "slemicro55o"
    string_registry = false

  }
  proxy_containerized = {
    mac   = "aa:b2:92:05:00:02"
    name  = "proxy"
    image = "slemicro55o"
    string_registry = false
  }
  monitoring_server = {
    mac  = "aa:b2:92:05:00:03"
    name = "monitoring"
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
  sles15sp3_minion = {
    mac  = "aa:b2:92:05:00:11"
    name = "sles15sp3-minion"
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
  centos7_minion = {
    mac  = "aa:b2:92:05:00:17"
    name = "centos7-minion"
  }
  rocky8_minion = {
    mac  = "aa:b2:92:05:00:18"
    name = "rocky8-minion"
  }
  alma8_minion = {
    mac  = "aa:b2:92:05:00:19"
    name = "alma8-minion"
  }
  rocky9_minion = {
    mac  = "aa:b2:92:05:00:21"
    name = "rocky9-minion"
  }
  alma9_minion = {
    mac  = "aa:b2:92:05:00:22"
    name = "alma9-minion"
  }
  oracle9_minion = {
    mac  = "aa:b2:92:05:00:23"
    name = "oracle9-minion"
  }
  liberty9_minion = {
    mac  = "aa:b2:92:05:00:25"
    name = "liberty9-minion"
  }
  ubuntu2204_minion = {
    mac  = "aa:b2:92:05:00:1b"
    name = "ubuntu2204-minion"
  }
  debian12_minion = {
    mac  = "aa:b2:92:05:00:1c"
    name = "debian12-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:92:05:00:1d"
    name = "ubuntu2404-minion"
  }
  opensuse156arm_minion = {
    mac  = "aa:b2:92:42:00:0a"
    name = "opensuse156arm-minion"
  }
  salt_migration_minion = {
    mac  = "aa:b2:92:05:00:2f"
    name = "salt-migration-minion"
  }
  sles15sp5s390_minion = {
    mac    = "02:00:00:02:01:32"
    name   = "sles15sp5s390-minion"
    userid = "S50MISLC"
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

  # SSH Minions
  sles12sp5_sshminion = {
    mac  = "aa:b2:92:05:00:30"
    name = "sles12sp5-sshminion"
  }
  sles15sp3_sshminion = {
    mac  = "aa:b2:92:05:00:31"
    name = "sles15sp3-sshminion"
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
  centos7_sshminion = {
    mac  = "aa:b2:92:05:00:37"
    name = "centos7-sshminion"
  }
  rocky8_sshminion = {
    mac  = "aa:b2:92:05:00:38"
    name = "rocky8-sshminion"
  }
  alma8_sshminion = {
    mac  = "aa:b2:92:05:00:39"
    name = "alma8-sshminion"
  }
  rocky9_sshminion = {
    mac  = "aa:b2:92:05:00:41"
    name = "rocky9-sshminion"
  }
  alma9_sshminion = {
    mac  = "aa:b2:92:05:00:42"
    name = "alma9-sshminion"
  }
  oracle9_sshminion = {
    mac  = "aa:b2:92:05:00:43"
    name = "oracle9-sshminion"
  }
  liberty9_sshminion = {
    mac  = "aa:b2:92:05:00:45"
    name = "liberty9-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:92:05:00:3b"
    name = "ubuntu2204-sshminion"
  }
  debian12_sshminion = {
    mac  = "aa:b2:92:05:00:3c"
    name = "debian12-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:92:05:00:3d"
    name = "ubuntu2404-sshminion"
  }
  opensuse156arm_sshminion = {
    mac  = "aa:b2:92:42:00:0b"
    name = "opensuse156arm-sshminion"
  }
  sles15sp5s390_sshminion = {
    mac    = "02:00:00:02:01:33"
    name   = "sles15sp5s390-sshminion"
    userid = "S50SSSLC"
  }
  # Note: Amazon Linux 2023 is not present in SUMA 5.0
  product_version = "5.0-released"
  name_prefix     = "suma-bv-50micro-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-qe/job/manager-5.0-micro-qe-build-validation-BACKUP"
}

BASE_CONFIGURATION = {
  base_core = {
    images             = [ "sles15sp5o", "sles15sp7o", "opensuse156o", "slemicro55o" ]
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
    images             = [ "almalinux8o", "almalinux9o", "centos7o", "oraclelinux9o", "rocky8o", "rocky9o", "libertylinux9o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "tatooine.mgr.slc1.suse.org" # Share base_old_sle hypervisor
  }
  base_new_sle = {
    images             = [ "sles15sp3o", "sles15sp4o", "sles15sp5o", "sles15sp6o", "sles15sp7o", "slemicro52-ign", "slemicro53-ign", "slemicro54-ign", "slemicro55o", "slmicro60o", "slmicro61o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "florina.mgr.slc1.suse.org"
  }
  base_retail = {
    images             = ["sles15sp6o","sles15sp7o", "opensuse156o", "slemicro55o"]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = "192.168.50.0/24"
    hypervisor         = "terminus.mgr.slc1.suse.org"
  }
  base_deblike = {
    images             = ["ubuntu2204o", "ubuntu2404o", "debian12o"]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "trantor.mgr.slc1.suse.org"
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
LOCATION              = "slc1"
