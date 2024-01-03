############ Nuremberg unique variables ############

DOMAIN            = "mgr.suse.de"
MIRROR            = "minima-mirror-ci-bv.mgr.suse.de"
DOWNLOAD_ENDPOINT = "minima-mirror-ci-bv.mgr.suse.de"
USE_MIRROR_IMAGES = false
GIT_PROFILES_REPO = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/internal_nue"
ENVIRONMENT_CONFIGURATION = {
  1 = {
    mac = {
      controller     = "aa:b2:93:01:03:50"
      server         = "aa:b2:93:01:03:51"
      proxy          = "aa:b2:93:01:03:52"
      suse-minion    = "aa:b2:93:01:03:54"
      suse-sshminion = "aa:b2:93:01:03:55"
      redhat-minion  = "aa:b2:93:01:03:56"
      debian-minion  = "aa:b2:93:01:03:57"
      build-host     = "aa:b2:93:01:03:59"
      kvm-host       = "aa:b2:93:01:03:5a"
      nested-vm      = "aa:b2:93:01:03:5b"
    }
    hypervisor = "suma-08.mgr.suse.de"
    additional_network = "192.168.111.0/24"
    pool = "ssd"
    bridge = "br0"
  },
  2 = {
    mac = {
      controller     = "aa:b2:93:01:03:5c"
      server         = "aa:b2:93:01:03:5d"
      proxy          = "aa:b2:93:01:03:5e"
      suse-minion    = "aa:b2:93:01:03:60"
      suse-sshminion = "aa:b2:93:01:03:61"
      redhat-minion  = "aa:b2:93:01:03:62"
      debian-minion  = "aa:b2:93:01:03:64"
      build-host     = "aa:b2:93:01:03:65"
      kvm-host       = "aa:b2:93:01:03:66"
      nested-vm      = "aa:b2:93:01:03:67"
    }
    hypervisor = "suma-08.mgr.suse.de"
    additional_network = "192.168.112.0/24"
    pool = "ssd"
    bridge = "br0"
  },
  3 = {
    mac = {
      controller     = "aa:b2:93:01:03:68"
      server         = "aa:b2:93:01:03:69"
      proxy          = "aa:b2:93:01:03:6a"
      suse-minion    = "aa:b2:93:01:03:6c"
      suse-sshminion = "aa:b2:93:01:03:6d"
      redhat-minion  = "aa:b2:93:01:03:6e"
      debian-minion  = "aa:b2:93:01:03:70"
      build-host     = "aa:b2:93:01:03:71"
      kvm-host       = "aa:b2:93:01:03:72"
      nested-vm      = "aa:b2:93:01:03:73"
    }
    hypervisor = "suma-08.mgr.suse.de"
    additional_network = "192.168.113.0/24"
    pool = "ssd"
    bridge = "br0"
  },
  4 = {
    mac = {
      controller     = "aa:b2:93:01:03:74"
      server         = "aa:b2:93:01:03:75"
      proxy          = "aa:b2:93:01:03:76"
      suse-minion    = "aa:b2:93:01:03:78"
      suse-sshminion = "aa:b2:93:01:03:79"
      redhat-minion  = "aa:b2:93:01:03:7a"
      debian-minion  = "aa:b2:93:01:03:7c"
      build-host     = "aa:b2:93:01:03:7d"
      kvm-host       = "aa:b2:93:01:03:7e"
      nested-vm      = "aa:b2:93:01:03:7f"
    }
    hypervisor = "suma-08.mgr.suse.de"
    additional_network = "192.168.114.0/24"
    pool = "ssd"
    bridge = "br0"
  },
  5 = {
    mac = {
      controller     = "aa:b2:93:01:03:80"
      server         = "aa:b2:93:01:03:81"
      proxy          = "aa:b2:93:01:03:82"
      suse-minion    = "aa:b2:93:01:03:84"
      suse-sshminion = "aa:b2:93:01:03:85"
      redhat-minion  = "aa:b2:93:01:03:86"
      debian-minion  = "aa:b2:93:01:03:88"
      build-host     = "aa:b2:93:01:03:89"
      kvm-host       = "aa:b2:93:01:03:8a"
      nested-vm      = "aa:b2:93:01:03:8b"
    }
    hypervisor = "suma-08.mgr.suse.de"
    additional_network = "192.168.115.0/24"
    pool = "ssd"
    bridge = "br0"
  },
  6 = {
    mac = {
      controller     = "aa:b2:93:01:03:8c"
      server         = "aa:b2:93:01:03:8d"
      proxy          = "aa:b2:93:01:03:8e"
      suse-minion    = "aa:b2:93:01:03:90"
      suse-sshminion = "aa:b2:93:01:03:91"
      redhat-minion  = "aa:b2:93:01:03:92"
      debian-minion  = "aa:b2:93:01:03:94"
      build-host     = "aa:b2:93:01:03:95"
      kvm-host       = "aa:b2:93:01:03:96"
      nested-vm      = "aa:b2:93:01:03:97"
    }
    hypervisor = "suma-08.mgr.suse.de"
    additional_network = "192.168.116.0/24"
    pool = "ssd"
    bridge = "br0"
  }
}
