############ Nuremberg unique variables ############

DOMAIN            = "mgr.suse.de"
MIRROR            = "minima-mirror-ci-bv.mgr.suse.de"
DOWNLOAD_ENDPOINT = "minima-mirror-ci-bv.mgr.suse.de"
USE_MIRROR_IMAGES = false
GIT_PROFILES_REPO = "https://github.com/uyuni-project/uyuni.git#:testsuite/features/profiles/temporary"
ENVIRONMENT_CONFIGURATION = {
  1 = {
    mac = {
      controller     = "aa:b2:93:01:03:50"
      server         = "aa:b2:93:01:03:51"
      proxy          = "aa:b2:93:01:03:52"
      suse-minion    = "aa:b2:93:01:03:54"
      suse-sshminion = "aa:b2:93:01:03:55"
      rhlike-minion  = "aa:b2:93:01:03:56"
      deblike-minion  = "aa:b2:93:01:03:57"
      build-host     = "aa:b2:93:01:03:59"
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
      rhlike-minion  = "aa:b2:93:01:03:62"
      deblike-minion  = "aa:b2:93:01:03:63"
      build-host     = "aa:b2:93:01:03:65"
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
      rhlike-minion  = "aa:b2:93:01:03:6e"
      deblike-minion  = "aa:b2:93:01:03:6f"
      build-host     = "aa:b2:93:01:03:71"
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
      rhlike-minion  = "aa:b2:93:01:03:7a"
      deblike-minion  = "aa:b2:93:01:03:7b"
      build-host     = "aa:b2:93:01:03:7d"
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
      rhlike-minion  = "aa:b2:93:01:03:86"
      deblike-minion  = "aa:b2:93:01:03:87"
      build-host     = "aa:b2:93:01:03:89"
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
      rhlike-minion  = "aa:b2:93:01:03:92"
      deblike-minion  = "aa:b2:93:01:03:93"
      build-host     = "aa:b2:93:01:03:95"
    }
    hypervisor = "suma-08.mgr.suse.de"
    additional_network = "192.168.116.0/24"
    pool = "ssd"
    bridge = "br0"
  }
}
