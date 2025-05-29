
from typing import Dict, Set, List

# Dictionary for SUMA 510 minion tools and repositories
v51_nodes_minion_tools: Dict[str, Set[str]] = {
    "alma8_minion": {"/RES-8:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-8-x86_64-Media1/"},
    "amazon2023_minion": {"/EL-9:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-9-x86_64-Media1/"},
    "alma9_minion": {"/EL-9:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-9-x86_64-Media1/"},
    "centos7_minion": {"/RES-7:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-EL7-POOL-x86_64-Media/"},
    "liberty9_minion": {"/EL-9:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-9-x86_64-Media1/"},
    "opensuse156arm_minion": {"/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-aarch64-Media1/"},
    "oracle9_minion": {"/EL-9:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-9-x86_64-Media1/"},

    "rhel9_minion": {"/EL-9:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-9-x86_64-Media1/"},
    "rocky8_minion": {"/RES-8:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-8-x86_64-Media1/"},
    "rocky9_minion": {"/EL-9:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-9-x86_64-Media1/"},
    "salt_migration_minion": {"/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"},
    "sle12sp5_minion": {"/SLE-12:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"},
    "sle15_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp1_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp2_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp3_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp4_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp5_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp5s390_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-s390x-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp6_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp7_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "slemicro51_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE-Micro5-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "slemicro52_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE-Micro5-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "slemicro53_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE-Micro5-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "slemicro54_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE-Micro5-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "slemicro55_minion": {
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE-Micro5-Pool-x86_64-Media1/",
        "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "slmicro60_minion": {
        "/SLFO:/Products:/MultiLinuxManagerTools:/SL-Micro-6:/ToTest/product/repo/Multi-Linux-ManagerTools-SL-Micro-6-x86_64/"
    },
    "slmicro61_minion": {
        "/SLFO:/Products:/MultiLinuxManagerTools:/SL-Micro-6:/ToTest/product/repo/Multi-Linux-ManagerTools-SL-Micro-6-x86_64/"
    }
}

# Dictionary for SUMA 5.1 Server and Proxy
v51_nodes: Dict[str, Set[str]] = {
    "server": {"/SLFO:/Products:/Multi-Linux-Manager:/5.1:/ToTest/product/repo/Multi-Linux-Manager-Server-5.1-x86_64/"},
    "proxy": {
        "/SLFO:/Products:/Multi-Linux-Manager:/5.1:/ToTest/product/repo/Multi-Linux-Manager-Proxy-5.1-x86_64/",
        "/SLFO:/Products:/Multi-Linux-Manager:/5.1:/ToTest/product/repo/Multi-Linux-Manager-Retail-Branch-Server-5.1-x86_64/",
        "/SLFO:/Products:/MultiLinuxManagerTools:/SL-Micro-6:/ToTest/product/repo/Multi-Linux-ManagerTools-SL-Micro-6-x86_64/"
    }
}

def get_v51_nodes_sorted() -> Dict[str, List[str]]:
    v51_nodes.update(v51_nodes_minion_tools)
    return {k: sorted(v) for k, v in v51_nodes.items()}