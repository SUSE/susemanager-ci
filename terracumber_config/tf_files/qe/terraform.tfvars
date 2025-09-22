ENVIRONMENT_CONFIGURATION = {
  maxime = {
    mac = {
      controller     = "aa:b2:93:01:01:8c"
      server         = "aa:b2:93:01:01:8d"
      proxy          = "aa:b2:93:01:01:8e"
      suse-client    = "aa:b2:93:01:01:8f"
      suse-minion    = "aa:b2:93:01:01:90"
      suse-sshminion = "aa:b2:93:01:01:91"
      rhlike-minion  = "aa:b2:93:01:01:92"
      deblike-minion = "aa:b2:93:01:01:93"
      build-host     = "aa:b2:93:01:01:94"
      kvm-build      = "aa:b2:93:01:01:95"
    }
    hypervisor          = "suma-05.mgr.suse.de"
    pool                = "mnoel_disks"
    bridge              = "br0"
    additional_network  = "192.168.10.0/24"
    dhcp_user           = "mnoel"
  }
}