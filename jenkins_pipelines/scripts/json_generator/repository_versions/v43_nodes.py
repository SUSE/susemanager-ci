
from typing import Dict, Set, List

# dictionary for 4.3 client tools
v43_client_tools: dict[str, Set[str]] = {
    "sle12sp5_client": {"/SUSE_Updates_SLE-Manager-Tools_12_x86_64/"},
    "sle12sp5_minion": {"/SUSE_Updates_SLE-Manager-Tools_12_x86_64/"},
    "sle15_client": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                     "/SUSE_Updates_SLE-Product-SLES_15-LTSS_x86_64/"},
    "sle15_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                     "/SUSE_Updates_SLE-Product-SLES_15-LTSS_x86_64/"},
    "sle15sp1_client": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"},
    "sle15sp1_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"},
    "sle15sp2_client": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP2-LTSS_x86_64/"},
    "sle15sp2_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP2-LTSS_x86_64/"},
    "sle15sp3_client": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP3_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP3_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP3-LTSS_x86_64/"},
    "sle15sp3_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP3_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP3_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP3-LTSS_x86_64/"},
    "sle15sp4_client": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP4_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP4_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP4-LTSS_x86_64/"},
    "sle15sp4_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP4_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP4_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP4-LTSS_x86_64/"},
    "sle15sp5_client": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP5_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP5_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP5-LTSS_x86_64/"},
    "sle15sp5_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP5_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP5_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP5-LTSS_x86_64/"},
    "sle15sp6_client": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP6_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP6_x86_64/"},
    "sle15sp6_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP6_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP6_x86_64/",
                        "/SUSE_Updates_SLE-Module-Systems-Management_15-SP6_x86_64/"},
    "sle15sp7_client": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP7_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP7_x86_64/"},
    "sle15sp7_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP7_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP7_x86_64/",
                        "/SUSE_Updates_SLE-Module-Systems-Management_15-SP7_x86_64/"},
    "sle15sp5s390_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_s390x/",
                            "/SUSE_Updates_SLE-Module-Basesystem_15-SP5_s390x/",
                            "/SUSE_Updates_SLE-Module-Server-Applications_15-SP5_s390x/"},
    "centos7_client": {"/SUSE_Updates_RES_7-CLIENT-TOOLS_x86_64/"},
    "centos7_minion": {"/SUSE_Updates_RES_7-CLIENT-TOOLS_x86_64"},
    "rocky8_minion": {"/SUSE_Updates_RES_8-CLIENT-TOOLS_x86_64/"},
    "alma8_minion": {"/SUSE_Updates_RES_8-CLIENT-TOOLS_x86_64/"},
    "ubuntu2004_minion": {"/SUSE_Updates_Ubuntu_20.04-CLIENT-TOOLS_x86_64/"},
    "ubuntu2204_minion": {"/SUSE_Updates_Ubuntu_22.04-CLIENT-TOOLS_x86_64/"},
    "ubuntu2404_minion": {"/SUSE_Updates_Ubuntu_24.04-CLIENT-TOOLS_x86_64/"},
    "debian12_minion": {"/SUSE_Updates_Debian_12-CLIENT-TOOLS_x86_64/"},
    "opensuse156arm_minion": {"/SUSE_Updates_openSUSE-SLE_15.6/",
                              "/SUSE_Updates_SLE-Manager-Tools_15_aarch64/"},
    "rhel9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/"},
    "rocky9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/"},
    "alma9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/"},
    "liberty9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/"},
    "oracle9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/"},
    "amazon2023_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/"},
    "openeuler2403_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/"},
    "slemicro51_minion": {"/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SUSE-MicroOS_5.1_x86_64/"},
    "slemicro52_minion": {"/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SUSE-MicroOS_5.2_x86_64/"},
    "slemicro53_minion": {"/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SUSE-MicroOS_5.3_x86_64/",
                          "/SUSE_Updates_SLE-Micro_5.3_x86_64/"},
    "slemicro54_minion": {"/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SUSE-MicroOS_5.4_x86_64/",
                          "/SUSE_Updates_SLE-Micro_5.4_x86_64/"},
    "slemicro55_minion": {"/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SUSE-MicroOS_5.5_x86_64/",
                          "/SUSE_Updates_SLE-Micro_5.5_x86_64/"},
    "slmicro60_minion": {"/SUSE_Updates_SLE-Manager-Tools-For-Micro_6_x86_64/",
                         "/SUSE_Updates_SUSE-MicroOS_6.0_x86_64/",
                         "/SUSE_Updates_SLE-Micro_6.0_x86_64/"},
    "slmicro61_minion": {"/SUSE_Updates_SLE-Manager-Tools-For-Micro_6_x86_64/",
                         "/SUSE_Updates_SUSE-MicroOS_6.1_x86_64/",
                         "/SUSE_Updates_SLE-Micro_6.1_x86_64/"},
    "salt_migration_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                              "/SUSE_Updates_SLE-Module-Basesystem_15-SP5_x86_64/",
                              "/SUSE_Updates_SLE-Module-Server-Applications_15-SP5_x86_64/"},
}

# Dictionary for SUMA 4.3 Server and Proxy
v43_nodes: Dict[str, Set[str]] = {
    "server": {"/SUSE_Updates_SLE-Module-SUSE-Manager-Server_4.3_x86_64/",
               "/SUSE_Updates_SLE-Product-SUSE-Manager-Server_4.3_x86_64/",
               "/SUSE_Updates_SLE-Product-SUSE-Manager-Server_4.3-LTS_x86_64/",
               "/SUSE_Updates_SLE-Module-Basesystem_15-SP4_x86_64/",
               "/SUSE_Updates_SLE-Module-Web-Scripting_15-SP4_x86_64/",
               "/SUSE_Updates_SLE-Module-Server-Applications_15-SP4_x86_64/"},
    "proxy": {"/SUSE_Updates_SLE-Module-SUSE-Manager-Proxy_4.3_x86_64/",
              "/SUSE_Updates_SLE-Product-SUSE-Manager-Proxy_4.3_x86_64/",
              "/SUSE_Updates_SLE-Product-SUSE-Manager-Proxy_4.3-LTS_x86_64/",
              "/SUSE_Updates_SLE-Module-Basesystem_15-SP4_x86_64/",
              "/SUSE_Updates_SLE-Module-Server-Applications_15-SP4_x86_64/"}
}

def get_v43_nodes_sorted() -> Dict[str, List[str]]:
    """
    Merge v43_nodes (server/proxy) with v43_client_tools (clients),
    returning a dictionary with sorted lists of repository paths.

    Notes:
    - v43_nodes: Dict[str, Set[str]] (server/proxy paths)
    - v43_client_tools: Dict[str, Set[str]] (client tool paths)
    - No need to worry about duplicates; simply merge the dictionaries.
    - The sets are converted into sorted lists for deterministic ordering.

    Returns:
        Dict[str, List[str]]: Each node type maps to a sorted list of repository paths.
    """
    v43_nodes.update(v43_client_tools)
    return {k: sorted(v) for k, v in v43_nodes.items()}
