from typing import Dict, Set, List, Tuple

# Shared IBS URL prefix
from .v51_nodes import IBS_URL_PREFIX
# TODO: When implementing non-beta 5.3 support, import from v52_nodes:
# from .v52_nodes import (
#     v52_nodes_static_client_tools_repositories,
#     v52_nodes_dynamic_client_tools_repos,
# )

# --- BETA 5.3 REPOSITORIES (PLACEHOLDER FOR FUTURE) ---
# TODO: These were originally defined for 5.2 beta but are preserved here
# for when 5.3 beta is needed in the future.

v53_uyuni_tools_sles_repos_beta: Dict[str, Set[str]] = {
    "server" : {"/SUSE_Updates_Multi-Linux-Manager-Server-SLE_5.3_x86_64/",
                "/SUSE_Updates_SLE-Module-Server-Applications_15-SP7_x86_64/",
                "/SUSE_Updates_SLE-Module-Basesystem_15-SP7_x86_64/",
                "/SUSE_Updates_SLE-Module-Containers_15-SP7_x86_64/",
                "/SUSE_Updates_SLE-Module-Python3_15-SP7_x86_64/"},
    "proxy" : { "/SUSE_Updates_Multi-Linux-Manager-Proxy-SLE_5.3_x86_64/",
                "/SUSE_Updates_Multi-Linux-Manager-Retail-Branch-Server-SLE_5.3_x86_64/",
                "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-15_x86_64/",
                "/SUSE_Updates_SLE-Module-Server-Applications_15-SP7_x86_64/",
                "/SUSE_Updates_SLE-Module-Basesystem_15-SP7_x86_64/",
                "/SUSE_Updates_SLE-Module-Containers_15-SP7_x86_64/",
                "/SUSE_Updates_SLE-Module-Python3_15-SP7_x86_64/"},
}

# SLES 5.3 beta: fixed ToTest *image* repo path fragments for server/proxy (not MI
# maintenance suffixes). Values are joined with IBS_URL_PREFIX in
# get_v53_static_and_client_tools when variant == "sles" and beta is True.
# TODO: These paths need to be updated when 5.3 beta project is created
v53_uyuni_tools_sles_static_repos_beta: Dict[str, Dict[str, str]] = {
    "server": {
        "mlm53_sles_beta_totest_images_sp7": (
            "/SLE-15-SP7:/Update:/Products:/MultiLinuxManager53:/ToTest/"
            "images-SP7/repo/SUSE-Multi-Linux-Manager-Server-SLE-5.3-POOL-x86_64-Media1/"
        ),
    },
    "proxy": {
        "mlm53_sles_beta_totest_images_sp7_proxy": (
            "/SLE-15-SP7:/Update:/Products:/MultiLinuxManager53:/ToTest/"
            "images-SP7/repo/SUSE-Multi-Linux-Manager-Proxy-SLE-5.3-POOL-x86_64-Media1/"
        ),
    },
}

v53_uyuni_tools_micro_repos_beta: Dict[str, Dict[str, str]] = {
    "server": {
        "server_uyuni_tools": "/SLFO:/Products:/Multi-Linux-Manager:/5.3:/ToTest/product/repo/Multi-Linux-Manager-Server-5.3-x86_64/"},
    "proxy": {
        "proxy_uyuni_tools": "/SLFO:/Products:/Multi-Linux-Manager:/5.3:/ToTest/product/repo/Multi-Linux-Manager-Proxy-5.3-x86_64/",
        "retail_uyuni_tools": "/SLFO:/Products:/Multi-Linux-Manager:/5.3:/ToTest/product/repo/Multi-Linux-Manager-Retail-Branch-Server-5.3-x86_64/",
        "slmicro6_client_tools": "/SLFO:/Products:/MultiLinuxManagerTools-Beta:/SL-Micro-6:/ToTest/product/repo/Multi-Linux-ManagerTools-Beta-SL-Micro-6-x86_64/"
    }
}

# Beta client tools for 5.3 - uses MultiLinuxManagerTools-Beta :ToTest repos
# These are the actual beta client tools (not stable client tools reused from a previous version)
# When 5.3 goes stable, the stable path will use 5.2 client tools (imported from v52_nodes)
v53_nodes_static_client_tools_repositories_beta: Dict[str, Dict[str, str]] = {
    "slmicro62_minion": {
        "sles16_client_tools": "/SLFO:/Products:/MultiLinuxManagerTools-Beta:/SLES-16:/ToTest/product/repo/Multi-Linux-ManagerTools-Beta-SLE-16-x86_64/"
    },
    "sles160_minion": {
        "sles16_client_tools": "/SLFO:/Products:/MultiLinuxManagerTools-Beta:/SLES-16:/ToTest/product/repo/Multi-Linux-ManagerTools-Beta-SLE-16-x86_64/"
    },
}

v53_nodes_dynamic_client_tools_repos_beta: Dict[str, Set[str]] = {
    "debian12_minion": {"/SUSE_Updates_MultiLinuxManagerTools-Beta_Debian-12_x86_64/"},
    "debian13_minion": {"/SUSE_Updates_MultiLinuxManagerTools-Beta_Debian-13_x86_64/"},
    "ubuntu2204_minion": {"/SUSE_Updates_MultiLinuxManagerTools-Beta_Ubuntu-22.04_x86_64/"},
    "ubuntu2404_minion": {"/SUSE_Updates_MultiLinuxManagerTools-Beta_Ubuntu-24.04_x86_64/"},
    "alma8_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-8_x86_64/"},
    "alma10_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-10_x86_64/"},
    "amazon2023_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-9_x86_64/"},
    "alma9_minion": {"/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-9_x86_64/"},
    "centos7_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_RES-7_x86_64/"},
    "liberty10_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-10_x86_64/"},
    "liberty9_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-9_x86_64/"},
    "openeuler2403_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-9_x86_64/"},
    "opensuse156arm_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-15_aarch64/"},
    "opensuse160arm_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-16_aarch64/"},
    "oracle9_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-9_x86_64/"},
    "oracle10_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-10_x86_64/"},
    "rhel9_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-9_x86_64/"},
    "rocky8_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-8_x86_64/"},
    "rocky9_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-9_x86_64/"},
    "rocky10_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_EL-10_x86_64/"},
    "salt_migration_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-15_x86_64/" },
    "sle12sp5_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-12_x86_64/" },
    "sle15sp3_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-15_x86_64/" },
    "sle15sp4_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-15_x86_64/" },
    "sle15sp5_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-15_x86_64/", },
    "sle15sp5s390_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-15_s390x/" },
    "sle15sp6_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-15_x86_64/",
                         "/SUSE_Updates_SLE-Module-Development-Tools_15-SP6_x86_64/"},
    "sle15sp7_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-15_x86_64/",
                         "/SUSE_Updates_SLE-Module-Server-Applications_15-SP7_x86_64/",
                         "/SUSE_Updates_SLE-Module-Basesystem_15-SP7_x86_64/",
                         "/SUSE_Updates_SLE-Module-Python3_15-SP7_x86_64/",
                         "/SUSE_Updates_SLE-Module-Development-Tools_15-SP7_x86_64/"},
    "slemicro52_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-Micro-5_x86_64/" },
    "slemicro53_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-Micro-5_x86_64/" },
    "slemicro54_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-Micro-5_x86_64/" },
    "slemicro55_minion": { "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-Micro-5_x86_64/" }
}

def get_v53_static_and_client_tools(
    variant: str = "micro", beta: bool = False,
) -> Tuple[Dict[str, Dict[str, str]], Dict[str, List[str]]]:
    """
    Generate repositories for SUMA/MLM 5.3.

    When beta=True, uses v53 Beta-specific client tools (MultiLinuxManagerTools-Beta).
    When beta=False, should use 5.2 stable client tools (update imports when 5.3 stable is released).
    """
    # TODO: Implement 5.3 non-beta support when it is released.
    # When beta=True: uses v53 beta-specific repositories defined in this file.
    # When beta=False: currently not implemented (will likely reuse 5.2 stable client tools).
    if not beta:
        raise NotImplementedError("5.3 non-beta is not yet implemented")

    source_static_repos = v53_nodes_static_client_tools_repositories_beta
    source_dynamic_repos = v53_nodes_dynamic_client_tools_repos_beta
    source_micro_repos = v53_uyuni_tools_micro_repos_beta
    source_sles_repos = v53_uyuni_tools_sles_repos_beta

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
        if beta:
            for key in ("server", "proxy"):
                if key not in static_repos:
                    static_repos[key] = {}
                for name, path in v53_uyuni_tools_sles_static_repos_beta.get(key, {}).items():
                    static_repos[key][name] = f"{IBS_URL_PREFIX}{path}"
    else:
        raise ValueError(f"Invalid variant '{variant}'. Choose from: 'micro', 'sles'")

    dynamic_repos_sorted: Dict[str, List[str]] = {
        key: sorted(paths) for key, paths in dynamic_maintenance_repos.items()
    }
    return static_repos, dynamic_repos_sorted
