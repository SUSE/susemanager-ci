ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac    = "aa:b2:93:01:01:8c"
    name   = "controller"
    memory = 4096
    vcpu   = 4
  }
  server_containerized = {
    mac   = "aa:b2:93:01:01:8d"
    name  = "server"
    image = "slmicro62o"
    string_registry = true
    memory                    = 32768
    vcpu                      = 8
    main_disk_size            = 500
    repository_disk_size      = 0
    database_disk_size        = 0
    disable_auto_bootstrap    = false
    disable_auto_channel_sync = false
    use_os_released_updates   = false
    server_mounted_mirror     = ""
  }
  server2_containerized = {
    mac   = "aa:b2:93:01:01:98"
    name  = "prh1"
    image = "slmicro62o"
    string_registry = true
    deploy_hub_api      = false
    skip_server_install = true
    use_mirror          = false
  }
  proxy_containerized = {
    mac   = "aa:b2:93:01:01:8e"
    name  = "proxy"
    image = "slmicro62o"
    string_registry = true
    memory         = 2048
    vcpu           = 2
    main_disk_size = 200
  }

  # Standard Minions
  sles15sp7_minion = {
    mac  = "aa:b2:93:01:01:90"
    name = "suse-minion"
    memory = 2048
    vcpu   = 2
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:93:01:01:91"
    name = "suse-sshminion"
    memory = 2048
    vcpu   = 2
  }

  # Standard Minions
  rocky8_minion = {
    mac  = "aa:b2:93:01:01:92"
    name = "rhlike-minion"
    memory = 2048
    vcpu   = 2
  }

  # Standard Minions
  ubuntu2404_minion = {
    mac  = "aa:b2:93:01:01:93"
    name = "deblike-minion"
    memory = 2048
    vcpu   = 2
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:93:01:01:94"
    name = "build-host"
  }
  product_version = "5.2-nightly"
  name_prefix     = "maxime-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-5.1/job/maxime"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "mnoel_disks"
    bridge             = "br0"
    hypervisor         = "suma-05.mgr.suse.de"
    additional_network = "192.168.17.0/24"
  }
}
MAIL_SUBJECT          = "Results 5.1 Build Validation $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.1 Build Validation: Environment setup failed"
LOCATION              = "nue"
