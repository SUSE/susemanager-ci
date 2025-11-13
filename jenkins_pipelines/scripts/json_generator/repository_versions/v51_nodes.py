from typing import Dict, Set, List

IBS_URL_PREFIX="http://download.suse.de/ibs/SUSE:"
# Dictionary for SUMA 5.10 minion tools and repositories

v51_uyuni_tools_sles_repos: Dict[str, Set[str]] = {
    "server" : { "/SUSE_Updates_Multi-Linux-Manager-Server-SLE_5.1_x86_64/" },
    "proxy" : { "/SUSE_Updates_Multi-Linux-Manager-Proxy-SLE_5.1_x86_64/",
                "/SUSE_Updates_Multi-Linux-Manager-Retail-Branch-Server-SLE_5.1_x86_64/",
                "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_x86_64/"}
}

v51_uyuni_tools_micro_repos: Dict[str, Dict[str, str]] = {
    "server": {
        "server_uyuni_tools": "/SLFO:/Products:/Multi-Linux-Manager:/5.1:/ToTest/product/repo/Multi-Linux-Manager-Server-5.1-x86_64/"},
    "proxy": {
        "proxy_uyuni_tools": "/SLFO:/Products:/Multi-Linux-Manager:/5.1:/ToTest/product/repo/Multi-Linux-Manager-Proxy-5.1-x86_64/",
        "retail_uyuni_tools": "/SLFO:/Products:/Multi-Linux-Manager:/5.1:/ToTest/product/repo/Multi-Linux-Manager-Retail-Branch-Server-5.1-x86_64/",
        "slmicro6_client_tools": "/SLFO:/Products:/MultiLinuxManagerTools:/SL-Micro-6:/ToTest/product/repo/Multi-Linux-ManagerTools-SL-Micro-6-x86_64/"
    }
}

v51_nodes_static_client_tools_repositories: Dict[str, Dict[str, str]] = {
    "slmicro60_minion": {
        "slmicro6_client_tools": "/SLFO:/Products:/MultiLinuxManagerTools:/SL-Micro-6:/ToTest/product/repo/Multi-Linux-ManagerTools-SL-Micro-6-x86_64/"
    },
    "slmicro61_minion": {
        "slmicro6_client_tools": "/SLFO:/Products:/MultiLinuxManagerTools:/SL-Micro-6:/ToTest/product/repo/Multi-Linux-ManagerTools-SL-Micro-6-x86_64/"
    }
}

v51_nodes_dynamic_client_tools_repos: Dict[str, Set[str]] = {
    "debian12_minion": {"/SUSE_Updates_MultiLinuxManagerTools_Debian-12_x86_64/"},
    "ubuntu2204_minion": {"/SUSE_Updates_MultiLinuxManagerTools_Ubuntu-22.04_x86_64/"},
    "ubuntu2404_minion": {"/SUSE_Updates_MultiLinuxManagerTools_Ubuntu-24.04_x86_64/"},
    "alma8_minion": { "/SUSE_Updates_MultiLinuxManagerTools_EL-8_x86_64/"},
    "amazon2023_minion": { "/SUSE_Updates_MultiLinuxManagerTools_EL-9_x86_64/"},
    "alma9_minion": {"/SUSE_Updates_MultiLinuxManagerTools_EL-9_x86_64/"},
    "centos7_minion": { "/SUSE_Updates_MultiLinuxManagerTools_RES-7_x86_64/"},
    "liberty9_minion": { "/SUSE_Updates_MultiLinuxManagerTools_EL-9_x86_64/"},
    "openeuler2403_minion": { "/SUSE_Updates_MultiLinuxManagerTools_EL-9_x86_64/"},
    "opensuse156arm_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_aarch64/"},
    "oracle9_minion": { "/SUSE_Updates_MultiLinuxManagerTools_EL-9_x86_64/"},
    "rhel9_minion": { "/SUSE_Updates_MultiLinuxManagerTools_EL-9_x86_64/"},
    "rocky8_minion": { "/SUSE_Updates_MultiLinuxManagerTools_EL-8_x86_64/"},
    "rocky9_minion": { "/SUSE_Updates_MultiLinuxManagerTools_EL-9_x86_64/"},
    "salt_migration_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_x86_64/" },
    "sle12sp5_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-12_x86_64/" },
    "sle15_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_x86_64/" },
    "sle15sp1_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_x86_64/" },
    "sle15sp2_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_x86_64/" },
    "sle15sp3_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_x86_64/" },
    "sle15sp4_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_x86_64/" },
    "sle15sp5_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_x86_64/", },
    "sle15sp5s390_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_s390x/" },
    "sle15sp6_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_x86_64/" },
    "sle15sp7_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-15_x86_64/" },
    "slemicro51_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-Micro-5_x86_64/" },
    "slemicro52_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-Micro-5_x86_64/" },
    "slemicro53_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-Micro-5_x86_64/" },
    "slemicro54_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-Micro-5_x86_64/" },
    "slemicro55_minion": { "/SUSE_Updates_MultiLinuxManagerTools_SLE-Micro-5_x86_64/" }
}

def get_v51_static_and_client_tools(variant: str = "micro") -> (Dict[str, Dict[str, str]], Dict[str, List[str]]):
    """
    Generate the full set of static and dynamic client tool repositories for SUMA 5.1.

    The function merges static client repositories with Uyuni server/proxy repositories,
    prepends the IBS URL prefix, and returns both static and dynamic sets in a
    deterministic, sorted form.

    Parameters:
        variant (str): Either "micro" or "sles", determines which Uyuni tool set to use.
                       "micro" → v51_uyuni_tools_micro_repos (static)
                       "sles"  → v51_uyuni_tools_sles_repos (dynamic)

    Returns:
        Tuple[
            Dict[str, Dict[str, str]],  # static_repos
                - Maps node IDs (e.g., "alma8_minion", "server", "proxy" for 'micro' variant) to
                  repo names → full IBS URLs.
            Dict[str, List[str]]        # dynamic_client_tools_repos
                - Maps dynamic client nodes (e.g., "debian12_minion", "server", "proxy" for 'sles' variant) to
                  a sorted list of full IBS URLs.
        ]

    Type and structure notes:
    1. Static repositories:
       - Input: v51_nodes_static_client_tools_repositories (Dict[str, Dict[str, str]])
       - Merged with Uyuni server/proxy repos for the 'micro' variant
       - Output: Dict[str, Dict[str, str]] with full URLs

    2. Dynamic client tool repositories:
       - Input: v51_nodes_dynamic_client_tools_repos (Dict[str, Set[str]])
       - Merged with Uyuni server/proxy repos for the 'sles' variant
       - Output: Dict[str, List[str]] with sorted full URLs
       - Mirrors the pattern in v43/v50: sets of paths are converted to sorted lists.

    Example:
        static_repos, dynamic_repos = get_v51_static_and_client_tools("micro")
        static_repos["server"]["server_uyuni_tools"]
        dynamic_repos["debian12_minion"][0]
        # Example for the sles variant:
        # static_repos, dynamic_repos = get_v51_static_and_client_tools("sles")
        # dynamic_repos["server"][0]
    """
    # 1. Initialize static repositories with IBS prefix
    static_repos: Dict[str, Dict[str, str]] = {
        key: {name: f"{IBS_URL_PREFIX}{path}" for name, path in subdict.items()}
        for key, subdict in v51_nodes_static_client_tools_repositories.items()
    }

    # 2. Initialize dynamic repositories with a *copy* to be able to modify the sets
    # Note: The final conversion to List[str] with sorting is done later.
    dynamic_maintenance_repos: Dict[str, Set[str]] = {
        key: set(paths) for key, paths in v51_nodes_dynamic_client_tools_repos.items()
    }

    # 3. Select Uyuni tools based on variant and merge into the appropriate structure
    if variant == "micro":
        uyuni_tools = v51_uyuni_tools_micro_repos
        # Merge uyuni server/proxy into static_repos for 'micro' variant
        for key in ("server", "proxy"):
            if key not in static_repos:
                static_repos[key] = {}
            # uyuni_tools is Dict[str, Dict[str, str]]
            for name, path in uyuni_tools.get(key, {}).items():
                static_repos[key][name] = f"{IBS_URL_PREFIX}{path}"

    elif variant == "sles":
        uyuni_tools = v51_uyuni_tools_sles_repos
        # Merge uyuni server/proxy into dynamic_maintenance_repos for 'sles' variant
        for key in ("server", "proxy"):
            if key not in dynamic_maintenance_repos:
                dynamic_maintenance_repos[key] = set()
            # uyuni_tools is Dict[str, Set[str]]
            # name is the path, which is added to the set of paths for the node
            for path in uyuni_tools.get(key, set()):
                dynamic_maintenance_repos[key].add(path)

    else:
        raise ValueError(f"Invalid variant '{variant}'. Choose from: 'micro', 'sles'")

    return static_repos, dynamic_maintenance_repos
