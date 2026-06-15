from typing import Dict, Set, List, Tuple

# Import the shared client tools from 5.1 for non-beta usage
from .v51_nodes import (
    v51_nodes_static_client_tools_repositories,
    v51_nodes_dynamic_client_tools_repos,
    IBS_URL_PREFIX,
)

# --- NON-BETA 5.2 REPOSITORIES ---
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

# SLES 5.2: static ToTest image repos for server/proxy
v52_uyuni_tools_sles_static_repos: Dict[str, Dict[str, str]] = {
    "server": {
        "mlm52_sles_totest_images_sp7": (
            "/SLE-15-SP7:/Update:/Products:/MultiLinuxManager52:/ToTest/"
            "images-SP7/repo/SUSE-Multi-Linux-Manager-Server-SLE-5.2-POOL-x86_64-Media1/"
        ),
    },
    "proxy": {
        "mlm52_sles_totest_images_sp7_proxy": (
            "/SLE-15-SP7:/Update:/Products:/MultiLinuxManager52:/ToTest/"
            "images-SP7/repo/SUSE-Multi-Linux-Manager-Proxy-SLE-5.2-POOL-x86_64-Media1/"
        ),
    },
}

# 5.2 uses exactly the same client tools structure as 5.1

def get_v52_static_and_client_tools(
    variant: str = "micro",
) -> Tuple[Dict[str, Dict[str, str]], Dict[str, List[str]]]:
    # 5.2 uses exactly the same client tools structure as 5.1
    source_static_repos = v51_nodes_static_client_tools_repositories
    source_dynamic_repos = v51_nodes_dynamic_client_tools_repos
    source_micro_repos = v52_uyuni_tools_micro_repos
    source_sles_repos = v52_uyuni_tools_sles_repos

    static_repos: Dict[str, Dict[str, str]] = {
        key: {name: f"{IBS_URL_PREFIX}{path}" for name, path in subdict.items()}
        for key, subdict in source_static_repos.items()
    }

    dynamic_maintenance_repos: Dict[str, Set[str]] = {
        key: set(paths) for key, paths in source_dynamic_repos.items()
    }

    if variant == "micro":
        uyuni_tools = source_micro_repos
        for key in ("server", "proxy"):
            if key not in static_repos:
                static_repos[key] = {}
            for name, path in uyuni_tools.get(key, {}).items():
                static_repos[key][name] = f"{IBS_URL_PREFIX}{path}"

    elif variant == "sles":
        uyuni_tools = source_sles_repos
        for key in ("server", "proxy"):
            if key not in dynamic_maintenance_repos:
                dynamic_maintenance_repos[key] = set()
            for path in uyuni_tools.get(key, set()):
                dynamic_maintenance_repos[key].add(path)
        # Add static ToTest image repos for server/proxy
        for key in ("server", "proxy"):
            if key not in static_repos:
                static_repos[key] = {}
            for name, path in v52_uyuni_tools_sles_static_repos.get(key, {}).items():
                static_repos[key][name] = f"{IBS_URL_PREFIX}{path}"
    else:
        raise ValueError(f"Invalid variant '{variant}'. Choose from: 'micro', 'sles'")

    dynamic_repos_sorted: Dict[str, List[str]] = {
        key: sorted(paths) for key, paths in dynamic_maintenance_repos.items()
    }
    return static_repos, dynamic_repos_sorted
