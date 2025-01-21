############ Provo unique variables ############

DOMAIN            = "mgr.prv.suse.net"
MIRROR            = "minima-mirror-ci-bv.mgr.prv.suse.net"
DOWNLOAD_ENDPOINT = "minima-mirror-ci-bv.mgr.prv.suse.net"
USE_MIRROR_IMAGES = true
GIT_PROFILES_REPO = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_prv"
ENVIRONMENT_CONFIGURATION = {
  1 = {
    mac = {
      controller     = "aa:b2:92:04:00:00"
      server         = "aa:b2:92:04:00:01"
      proxy          = "aa:b2:92:04:00:02"
      suse-minion    = "aa:b2:92:04:00:04"
      suse-sshminion = "aa:b2:92:04:00:05"
      rhlike-minion  = "aa:b2:92:04:00:06"
      deblike-minion = "aa:b2:92:04:00:07"
      build-host     = "aa:b2:92:04:00:09"
    }
    hypervisor = "romulus.mgr.prv.suse.net"
    additional_network = "192.168.101.0/24"
    pool = "ssd"
    bridge = "br1"
  },
  2 = {
    mac = {
      controller     = "aa:b2:92:04:00:10"
      server         = "aa:b2:92:04:00:11"
      proxy          = "aa:b2:92:04:00:12"
      suse-minion    = "aa:b2:92:04:00:14"
      suse-sshminion = "aa:b2:92:04:00:15"
      rhlike-minion  = "aa:b2:92:04:00:16"
      deblike-minion = "aa:b2:92:04:00:17"
      build-host     = "aa:b2:92:04:00:19"
    }
    hypervisor = "romulus.mgr.prv.suse.net"
    additional_network = "192.168.102.0/24"
    pool = "ssd"
    bridge = "br1"
  },
  3 = {
    mac = {
      controller     = "aa:b2:92:04:00:20"
      server         = "aa:b2:92:04:00:21"
      proxy          = "aa:b2:92:04:00:22"
      suse-minion    = "aa:b2:92:04:00:24"
      suse-sshminion = "aa:b2:92:04:00:25"
      rhlike-minion  = "aa:b2:92:04:00:26"
      deblike-minion = "aa:b2:92:04:00:27"
      build-host     = "aa:b2:92:04:00:29"
    }
    hypervisor = "vulcan.mgr.prv.suse.net"
    additional_network = "192.168.103.0/24"
    pool = "ssd"
    bridge = "br1"
  },
  4 = {
    mac = {
      controller     = "aa:b2:92:04:00:30"
      server         = "aa:b2:92:04:00:31"
      proxy          = "aa:b2:92:04:00:32"
      suse-minion    = "aa:b2:92:04:00:34"
      suse-sshminion = "aa:b2:92:04:00:35"
      rhlike-minion  = "aa:b2:92:04:00:36"
      deblike-minion = "aa:b2:92:04:00:37"
      build-host     = "aa:b2:92:04:00:39"
    }
    hypervisor = "vulcan.mgr.prv.suse.net"
    additional_network = "192.168.104.0/24"
    pool = "ssd"
    bridge = "br1"
  },
  5 = {
    mac = {
      controller     = "aa:b2:92:04:00:40"
      server         = "aa:b2:92:04:00:41"
      proxy          = "aa:b2:92:04:00:42"
      suse-minion    = "aa:b2:92:04:00:44"
      suse-sshminion = "aa:b2:92:04:00:45"
      rhlike-minion  = "aa:b2:92:04:00:46"
      deblike-minion = "aa:b2:92:04:00:47"
      build-host     = "aa:b2:92:04:00:49"
    }
    hypervisor = "hyperion.mgr.prv.suse.net"
    additional_network = "192.168.105.0/24"
    pool = "ssd"
    bridge = "br1"
  },
  6 = {
    mac = {
      controller     = "aa:b2:92:04:00:50"
      server         = "aa:b2:92:04:00:51"
      proxy          = "aa:b2:92:04:00:52"
      suse-minion    = "aa:b2:92:04:00:54"
      suse-sshminion = "aa:b2:92:04:00:55"
      rhlike-minion  = "aa:b2:92:04:00:56"
      deblike-minion = "aa:b2:92:04:00:57"
      build-host     = "aa:b2:92:04:00:59"
    }
    hypervisor = "hyperion.mgr.prv.suse.net"
    additional_network = "192.168.106.0/24"
    pool = "ssd"
    bridge = "br1"
  },
  7 = {
    mac = {
      controller     = "aa:b2:92:04:00:60"
      server         = "aa:b2:92:04:00:61"
      proxy          = "aa:b2:92:04:00:62"
      suse-minion    = "aa:b2:92:04:00:64"
      suse-sshminion = "aa:b2:92:04:00:65"
      rhlike-minion  = "aa:b2:92:04:00:66"
      deblike-minion = "aa:b2:92:04:00:67"
      build-host     = "aa:b2:92:04:00:69"
    }
    hypervisor = "daiquiri.mgr.prv.suse.net"
    additional_network = "192.168.107.0/24"
    pool = "default"
    bridge = "br1"
  },
  8 = {
    mac = {
      controller     = "aa:b2:92:04:00:70"
      server         = "aa:b2:92:04:00:71"
      proxy          = "aa:b2:92:04:00:72"
      suse-minion    = "aa:b2:92:04:00:74"
      suse-sshminion = "aa:b2:92:04:00:75"
      rhlike-minion  = "aa:b2:92:04:00:76"
      deblike-minion = "aa:b2:92:04:00:77"
      build-host     = "aa:b2:92:04:00:79"
    }
    hypervisor = "daiquiri.mgr.prv.suse.net"
    additional_network = "192.168.108.0/24"
    pool = "default"
    bridge = "br1"
  },
  9 = {
    mac = {
      controller     = "aa:b2:92:04:00:80"
      server         = "aa:b2:92:04:00:81"
      proxy          = "aa:b2:92:04:00:82"
      suse-minion    = "aa:b2:92:04:00:84"
      suse-sshminion = "aa:b2:92:04:00:85"
      rhlike-minion  = "aa:b2:92:04:00:86"
      deblike-minion = "aa:b2:92:04:00:87"
      build-host     = "aa:b2:92:04:00:89"
    }
    hypervisor = "mojito.mgr.prv.suse.net"
    additional_network = "192.168.109.0/24"
    pool = "default"
    bridge = "br0"
  },
  10 = {
    mac = {
      controller     = "aa:b2:92:04:00:90"
      server         = "aa:b2:92:04:00:91"
      proxy          = "aa:b2:92:04:00:92"
      suse-minion    = "aa:b2:92:04:00:94"
      suse-sshminion = "aa:b2:92:04:00:95"
      rhlike-minion  = "aa:b2:92:04:00:96"
      deblike-minion = "aa:b2:92:04:00:97"
      build-host     = "aa:b2:92:04:00:99"
    }
    hypervisor = "mojito.mgr.prv.suse.net"
    additional_network = "192.168.110.0/24"
    pool = "default"
    bridge = "br0"
  }
}
