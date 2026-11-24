ENVIRONMENT_CONFIGURATION = {
  # Core Infrastructure
  controller = {
    mac    = "aa:b2:92:42:00:e0"
    name   = "controller"
    memory = 4096
    vcpu   = 4

    no_auth_registry         = "registry.mgr.suse.de"
    auth_registry            = "registry.mgr.suse.de:5000/cucutest"
    auth_registry_username   = "cucutest"
    auth_registry_password   = "cucusecret"
    server_http_proxy        = "http-proxy.mgr.suse.de:3128"
    custom_download_endpoint = "ftp://minima-mirror-ci-bv.mgr.suse.de:445"
  }
  server_containerized = {
    mac   = "aa:b2:92:42:00:e1"
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
    mac   = "aa:b2:92:42:00:e3"
    name  = "prh1"
    image = "slmicro62o"
    string_registry = true
    deploy_hub_api      = false
    skip_server_install = true
    use_mirror          = false
  }
  proxy_containerized = {
    mac   = "aa:b2:92:42:00:e2"
    name  = "proxy"
    image = "slmicro62o"
    string_registry = true
    memory         = 2048
    vcpu           = 2
    main_disk_size = 200
  }

  # Standard Minions
  sles15sp7_minion = {
    mac  = "aa:b2:92:42:00:e6"
    name = "suse-minion"
    memory = 2048
    vcpu   = 2
  }
  sles15sp7_sshminion = {
    mac  = "aa:b2:92:42:00:e8"
    name = "suse-sshminion"
    memory = 2048
    vcpu   = 2
  }

  # Standard Minions
  rocky8_minion = {
    mac  = "aa:b2:92:42:00:ea"
    name = "rhlike-minion"
    memory = 2048
    vcpu   = 2
  }

  # Standard Minions
  ubuntu2404_minion = {
    mac  = "aa:b2:92:42:00:eb"
    name = "deblike-minion"
    memory = 2048
    vcpu   = 2
  }
  sles15sp7_buildhost = {
    mac  = "aa:b2:92:42:00:ed"
    name = "build-host"
    terminal_private_name = "pxeboot"
    terminal_manufacturer = "Intel"
    terminal_product      = "Genuine"
    terminal_private_ip   = 4
  }
  product_version = "5.2-nightly"
  name_prefix     = "mlm-ci-52-podman-"
  url_prefix      = "https://jenkins.mgr.suse.de/job/manager-5.2-dev-acceptance-tests-podman"
}
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br0"
    hypervisor         = "suma-01.mgr.suse.de"
    additional_network = "192.168.52.0/24"
  }
}
MAIL_SUBJECT          = "Results 5.2-PODMAN-PRG $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
MAIL_SUBJECT_ENV_FAIL = "Results 5.2-PODMAN-PRG: Environment setup failed"
LOCATION              = "prg2"
