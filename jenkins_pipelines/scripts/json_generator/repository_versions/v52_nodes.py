from typing import Dict, Set, List

# Import the shared client tools from 5.1
from .v51_nodes import (
    v51_nodes_static_client_tools_repositories,
    v51_nodes_dynamic_client_tools_repos,
    IBS_URL_PREFIX
)

# Define 5.2 specific Server and Proxy repositories (using 15-SP7)
v52_uyuni_tools_sles_repos: Dict[str, Set[str]] = {
    "server" : {"/SUSE_Updates_Multi-Linux-Manager-Server-SLE_5.2_x86_64/",
                "/SUSE_Updates_SLE-Module-Server-Applications_15-SP7_x86_64/",
                "/SUSE_Updates_SLE-Module-Basesystem_15-SP7_x86_64/",
                "/SUSE_Updates_SLE-Module-Containers_15-SP7_x86_64/",
                "/SUSE_Updates_SLE-Module-Python3_15-SP7_x86_64/"},
    "proxy" : { "/SUSE_Updates_Multi-Linux-Manager-Proxy-SLE_5.2_x86_64/",
                "/SUSE_Updates_Multi-Linux-Manager-Retail-Branch-Server-SLE_5.2_x86_64/",
                "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_x86_64/",
                "/SUSE_Updates_SLE-Module-Server-Applications_15-SP7_x86_64/",
                "/SUSE_Updates_SLE-Module-Basesystem_15-SP7_x86_64/",
                "/SUSE_Updates_SLE-Module-Containers_15-SP7_x86_64/",
                "/SUSE_Updates_SLE-Module-Python3_15-SP7_x86_64/"},
}

v52_uyuni_tools_micro_repos: Dict[str, Dict[str, str]] = {
    "server": {
        "server_uyuni_tools": "/SLFO:/Products:/Multi-Linux-Manager:/5.2:/ToTest/product/repo/Multi-Linux-Manager-Server-5.2-x86_64/"},
    "proxy": {
        "proxy_uyuni_tools": "/SLFO:/Products:/Multi-Linux-Manager:/5.2:/ToTest/product/repo/Multi-Linux-Manager-Proxy-5.2-x86_64/",
        "retail_uyuni_tools": "/SLFO:/Products:/Multi-Linux-Manager:/5.2:/ToTest/product/repo/Multi-Linux-Manager-Retail-Branch-Server-5.2-x86_64/",
        "slmicro6_client_tools": "/SLFO:/Products:/MultiLinuxManagerTools:/SL-Micro-6:/ToTest/product/repo/Multi-Linux-ManagerTools-SL-Micro-6-x86_64/"
    }
}

def get_v52_static_and_client_tools(variant: str = "micro") -> (Dict[str, Dict[str, str]], Dict[str, List[str]]):
    # 1. Initialize static repositories using the shared 5.1 client tools
    static_repos: Dict[str, Dict[str, str]] = {
        key: {name: f"{IBS_URL_PREFIX}{path}" for name, path in subdict.items()}
        for key, subdict in v51_nodes_static_client_tools_repositories.items()
    }

    # 2. Initialize dynamic repositories using the shared 5.1 client tools
    dynamic_maintenance_repos: Dict[str, Set[str]] = {
        key: set(paths) for key, paths in v51_nodes_dynamic_client_tools_repos.items()
    }

    # 3. Select 5.2 Uyuni tools based on variant and merge
    if variant == "micro":
        uyuni_tools = v52_uyuni_tools_micro_repos
        for key in ("server", "proxy"):
            if key not in static_repos:
                static_repos[key] = {}
            for name, path in uyuni_tools.get(key, {}).items():
                static_repos[key][name] = f"{IBS_URL_PREFIX}{path}"

    elif variant == "sles":
        uyuni_tools = v52_uyuni_tools_sles_repos
        for key in ("server", "proxy"):
            if key not in dynamic_maintenance_repos:
                dynamic_maintenance_repos[key] = set()
            for path in uyuni_tools.get(key, set()):
                dynamic_maintenance_repos[key].add(path)

    else:
        raise ValueError(f"Invalid variant '{variant}'. Choose from: 'micro', 'sles'")

    return static_repos, dynamic_maintenance_repos
