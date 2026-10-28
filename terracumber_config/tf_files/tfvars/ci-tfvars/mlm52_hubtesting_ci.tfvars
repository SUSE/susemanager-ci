ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac    = "aa:b2:92:42:00:b0"
    name   = "controller"
    memory = 4096
    vcpu   = 4
  }
  server_containerized = {
    mac   = "aa:b2:92:42:00:b1"
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
    mac   = "aa:b2:92:42:00:b3"
    name  = "prh1"
    image = "slmicro62o"
    string_registry = true
    deploy_hub_api      = false
    skip_server_install = true
    use_mirror          = false
  }
  proxy_containerized = {
    mac   = "aa:b2:92:42:00:b2"
    name  = "proxy"
    image = "slmicro62o"
    string_registry = true
    memory         = 2048
    vcpu           = 2
    main_disk_size = 200
  }

  # Standard Minions
  sles15sp7_minion = {
    mac  = "aa:b2:92:42:00:b6"
    name = "suse-minion"
    memory = 2048
    vcpu   = 2
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:92:42:00:b8"
    name = "suse-sshminion"
    memory = 2048
    vcpu   = 2
  }

  # Standard Minions
  rocky8_minion = {
    mac  = "aa:b2:92:42:00:ba"
    name = "rhlike-minion"
    memory = 2048
    vcpu   = 2
  }

  # Standard Minions
  ubuntu2404_minion = {
    mac  = "aa:b2:92:42:00:bb"
    name = "deblike-minion"
    memory = 2048
    vcpu   = 2
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:92:42:00:bd"
    name = "build-host"
    terminal_private_name = "pxeboot"
  }
  product_version = "5.2-nightly"
  name_prefix     = "mlm-ci-52-hubtesting-"
  url_prefix      = "https://jenkins.mgr.suse.de/job/manager-5.2-dev-acceptance-tests-hubtesting"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br0"
    hypervisor         = "suma-01.mgr.suse.de"
    additional_network = "192.168.153.0/24"
  }
}
MAIL_SUBJECT          = "Results 5.2-PRG hubtesting $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.2-PRG hubtesting: Environment setup failed"
LOCATION              = "prg2"
