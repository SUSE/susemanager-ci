
from typing import Dict, Set, List

IBS_URL_PREFIX="http://download.suse.de/ibs"
# Dictionary for SUMA 510 minion tools and repositories
v51_nodes_static_repository: Dict[str, Set[str]] = {
    "server": {
        "server_uyuni_tools": "/SLFO:/Products:/Multi-Linux-Manager:/5.1:/ToTest/product/repo/Multi-Linux-Manager-Server-5.1-x86_64/"},
    "proxy": {
        "proxy_uyuni_tools": "/SLFO:/Products:/Multi-Linux-Manager:/5.1:/ToTest/product/repo/Multi-Linux-Manager-Proxy-5.1-x86_64/",
        "retail_uyuni_tools": "/SLFO:/Products:/Multi-Linux-Manager:/5.1:/ToTest/product/repo/Multi-Linux-Manager-Retail-Branch-Server-5.1-x86_64/",
        "slmicro6_client_tools": "/SLFO:/Products:/MultiLinuxManagerTools:/SL-Micro-6:/ToTest/product/repo/Multi-Linux-ManagerTools-SL-Micro-6-x86_64/"
    },
    "alma8_minion": {
        "RES_8_client_tools": "/RES-8:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-8-x86_64-Media1/"},
    "amazon2023_minion": {
        "EL_9_client_tools": "/EL-9:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-9-x86_64-Media1/"},
    "alma9_minion": {
        "EL_9_client_tools": "/EL-9:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-9-x86_64-Media1/"},
    "centos7_minion": {
        "RES_7_client_tools": "/RES-7:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-EL7-POOL-x86_64-Media/"},
    "liberty9_minion": {
        "EL_9_client_tools": "/EL-9:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-9-x86_64-Media1/"},
    "opensuse156arm_minion": {
        "sle15_arm_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-aarch64-Media1/"},
    "oracle9_minion": {
        "EL_9_client_tools": "/EL-9:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-9-x86_64-Media1/"},
    "rhel9_minion": {
        "EL_9_client_tools": "/EL-9:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-9-x86_64-Media1/"},
    "rocky8_minion": {
        "RES_8_client_tools": "/RES-8:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-8-x86_64-Media1/"},
    "rocky9_minion": {
        "EL_9_client_tools": "/EL-9:/Update:/Products:/MultiLinuxManagerTools/images/repo/MultiLinuxManagerTools-EL-9-x86_64-Media1/"},
    "salt_migration_minion": {
        "sle15_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "sle15_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle12sp5_minion": {
        "sle12_client_tools": "/SLE-12:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE12-Pool-x86_64-Media1/",
        "sle12_saltbundle": "/SLE-12:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15_minion": {
        "sle15_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "sle15_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp1_minion": {
        "sle15_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "sle15_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp2_minion": {
        "sle15_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "sle15_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp3_minion": {
        "sle15_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "sle15_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp4_minion": {
        "sle15_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "sle15_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp5_minion": {
        "sle15_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "sle15_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp5s390_minion": {
        "sle15_s390_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-s390x-Media1/",
        "sle15_s390_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp6_minion": {
        "sle15_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "sle15_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "sle15sp7_minion": {
        "sle15_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE15-Pool-x86_64-Media1/",
        "sle15_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "slemicro51_minion": {
        "slemicro_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE-Micro5-Pool-x86_64-Media1/",
        "slemicro_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "slemicro52_minion": {
        "slemicro_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE-Micro5-Pool-x86_64-Media1/",
        "slemicro_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "slemicro53_minion": {
        "slemicro_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE-Micro5-Pool-x86_64-Media1/",
        "slemicro_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "slemicro54_minion": {
        "slemicro_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE-Micro5-Pool-x86_64-Media1/",
        "slemicro_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "slemicro55_minion": {
        "slemicro_client_tools": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools/images/repo/ManagerTools-SLE-Micro5-Pool-x86_64-Media1/",
        "slemicro_saltbundle": "/SLE-15:/Update:/Products:/MultiLinuxManagerTools:/SaltBundle/standard/"
    },
    "slmicro60_minion": {
        "slmicro6_client_tools": "/SLFO:/Products:/MultiLinuxManagerTools:/SL-Micro-6:/ToTest/product/repo/Multi-Linux-ManagerTools-SL-Micro-6-x86_64/"
    },
    "slmicro61_minion": {
        "slmicro6_client_tools": "/SLFO:/Products:/MultiLinuxManagerTools:/SL-Micro-6:/ToTest/product/repo/Multi-Linux-ManagerTools-SL-Micro-6-x86_64/"
    }
}

v51_nodes_client_tools: Dict[str, Set[str]] = {
    "debian12_minion": {"/SUSE_Updates_MultiLinuxManagerTools_Debian-12_x86_64/"},
    "ubuntu2204_minion": {"/SUSE_Updates_MultiLinuxManagerTools_Ubuntu-22.04_x86_64/"},
    "ubuntu2404_minion": {"/SUSE_Updates_MultiLinuxManagerTools_Ubuntu-24.04_x86_64/"}
}

def get_v51_static_and_client_tools() -> (Dict[str, Dict[str, str]], Dict[str, List[str]]):
    # No change in structure, just keep the original dicts for static
    static_repos: Dict[str, Dict[str, str]] = {
        key: {name: f"{IBS_URL_PREFIX}{path}" for name, path in subdict.items()}
        for key, subdict in v51_nodes_static_repository.items()
    }

    client_tools: Dict[str, List[str]] = {
        key: sorted(paths) for key, paths in v51_nodes_client_tools.items()
    }

    return static_repos, client_tools
