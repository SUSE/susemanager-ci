ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac  = "aa:b2:93:04:05:6c"
    name = "controller"
  }
  server_containerized = {
    mac   = "aa:b2:93:04:05:6d"
    name  = "server"
    image = "tumbleweedo"
  }
  proxy_containerized = {
    mac   = "aa:b2:93:04:05:6e"
    name  = "proxy"
    image = "tumbleweedo"
  }
  monitoring_server = {
    mac  = "aa:b2:93:04:05:6f"
    name = "monitoring"
  }

  # Build Hosts
  sles15sp4_buildhost = {
    mac  = "aa:b2:93:04:05:71"
    name = "sles15sp4-build"
  }

  # Standard Minions
  sles12sp5_minion = {
    mac  = "aa:b2:93:04:05:7c"
    name = "sles12sp5-minion"
  }
  sles15sp3_minion = {
    mac  = "aa:b2:93:04:05:7d"
    name = "sles15sp3-minion"
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
  ubuntu2004_minion = {
    # Deprecated in base image list, but module exists in file
    mac  = "aa:b2:93:04:05:86"
    name = "ubuntu2004-minion"
  }
  ubuntu2204_minion = {
    mac  = "aa:b2:93:04:05:87"
    name = "ubuntu2204-minion"
  }
  ubuntu2404_minion = {
    mac  = "aa:b2:93:04:05:89"
    name = "ubuntu2404-minion"
  }
  debian12_minion = {
    mac  = "aa:b2:93:04:05:88"
    name = "debian12-minion"
  }
  opensuse156arm_minion = {
    mac  = "aa:b2:92:42:00:10"
    name = "opensuse156arm-minion-slc"
  }
  sles15sp5s390_minion = {
    mac    = "02:00:00:02:01:34"
    name   = "sles15sp5s390-minion"
    userid = "UYMMISLC"
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

  # SSH Minions
  sles12sp5_sshminion = {
    mac  = "aa:b2:93:04:05:9c"
    name = "sles12sp5-sshminion"
  }
  sles15sp3_sshminion = {
    mac  = "aa:b2:93:04:05:9d"
    name = "sles15sp3-sshminion"
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
  ubuntu2004_sshminion = {
    mac  = "aa:b2:93:04:05:a6"
    name = "ubuntu2004-sshminion"
  }
  ubuntu2204_sshminion = {
    mac  = "aa:b2:93:04:05:a7"
    name = "ubuntu2204-sshminion"
  }
  ubuntu2404_sshminion = {
    mac  = "aa:b2:93:04:05:a9"
    name = "ubuntu2404-sshminion"
  }
  debian12_sshminion = {
    mac  = "aa:b2:93:04:05:a8"
    name = "debian12-sshminion"
  }
  opensuse156arm_sshminion = {
    mac  = "aa:b2:92:42:00:11"
    name = "opensuse156arm-sshminion-slc"
  }
  sles15sp5s390_sshminion = {
    mac    = "02:00:00:02:01:35"
    name   = "sles15sp5s390-sshminion"
    userid = "UYMSSSLC"
  }

  product_version = "uyuni-master"
  name_prefix     = "uyuni-bv-master-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Uyuni/job/uyuni-master-qe-build-validation"
}

BASE_CONFIGURATIONS = {
  base_core = {
    images             = [ "tumbleweedo", "opensuse155o", "sles15sp7o" ]
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
    images             = [ "almalinux8o", "almalinux9o", "amazonlinux2023o", "centos7o", "libertylinux9o", "oraclelinux9o", "rocky8o", "rocky9o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "cosmopolitan.mgr.slc1.suse.org"
  }
  base_new_sle = {
    images             = [ "sles15sp3o", "sles15sp4o", "sles15sp5o", "sles15sp6o", "sles15sp7o", "slemicro52-ign", "slemicro53-ign" , "slemicro54-ign", "slemicro55o", "slmicro60o", "slmicro61o", "tumbleweedo" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "ginfizz.mgr.slc1.suse.org"
  }
  base_retail = {
    images             = [ "sles15sp6o", "sles15sp7o", "opensuse155o", "leapmicro55o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = "192.168.100.0/24"
    hypervisor         = "margarita.mgr.slc1.suse.org"
  }
  base_deblike = {
    images             = [ "ubuntu2204o", "ubuntu2404o", "debian12o" ]
    pool               = "ssd"
    bridge             = "br1"
    additional_network = null
    hypervisor         = "caipirinha.mgr.slc1.suse.org"
  }
}

MAIL_SUBJECT          = "Results Uyuni Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results Uyuni Build Validation: Environment setup failed"
LOCATION              = "slc1"
