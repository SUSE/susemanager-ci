environment_number = "1"

mac = {
  controller    = "aa:b2:92:04:00:00"
  server        = "aa:b2:92:04:00:01"
  proxy         = "aa:b2:92:04:00:02"
  suse-minion   = "aa:b2:92:04:00:04"
  suse-sshminion = "aa:b2:92:04:00:05"
  redhat-minion = "aa:b2:92:04:00:06"
  debian-minion = "aa:b2:92:04:00:07"
  build-host    = "aa:b2:92:04:00:09"
  pxeboot-minion = "?"
  kvm-host      = "aa:b2:92:04:00:0a"
  nested-vm     = "aa:b2:92:04:00:0b"
}

hypervisor = "romulus.mgr.prv.suse.net"
additional_network = "192.168.101.0/24"
