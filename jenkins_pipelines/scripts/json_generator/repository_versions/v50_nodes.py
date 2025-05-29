from typing import Dict, Set, List

# dictionary for 5.0 client tools
v50_client_tools_beta: dict[str, set[str]] = {
    "sle12sp5_client": {"/SUSE_Updates_SLE-Manager-Tools_12-BETA_x86_64/"},
    "sle12sp5_minion": {"/SUSE_Updates_SLE-Manager-Tools_12-BETA_x86_64/"},
    "sle15_client": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp1_client": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp1_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp2_client": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp2_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp3_client": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp3_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp4_client": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp4_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp5_client": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp5_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp6_client": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp6_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp7_client": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp7_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "sle15sp5s390_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_s390x/"},
    "centos7_client": {"/SUSE_Updates_RES_7-CLIENT-TOOLS-BETA_x86_64/"},
    "centos7_minion": {"/SUSE_Updates_RES_7-CLIENT-TOOLS-BETA_x86_64"},
    "rocky8_minion": {"/SUSE_Updates_RES_8-CLIENT-TOOLS-BETA_x86_64/"},
    "alma8_minion": {"/SUSE_Updates_RES_8-CLIENT-TOOLS-BETA_x86_64/"},
    "ubuntu2004_minion": {"/SUSE_Updates_Ubuntu_20.04-CLIENT-TOOLS-BETA_x86_64/"},
    "ubuntu2204_minion": {"/SUSE_Updates_Ubuntu_22.04-CLIENT-TOOLS-BETA_x86_64/"},
    "ubuntu2404_minion": {"/SUSE_Updates_Ubuntu_24.04-CLIENT-TOOLS-BETA_x86_64/"},
    "debian12_minion": {"/SUSE_Updates_Debian_12-CLIENT-TOOLS-BETA_x86_64/"},
    "opensuse156arm_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_aarch64/"},
    "rhel9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/"},
    "rocky9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/"},
    "alma9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/"},
    "oracle9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/"},
    "liberty9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/"},
    "amazon2023_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/"},
    "slemicro51_minion": {"/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "slemicro52_minion": {"/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "slemicro53_minion": {"/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "slemicro54_minion": {"/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "slemicro55_minion": {"/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "slmicro60_minion": {"/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_6_x86_64/",
                         "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "slmicro61_minion": {"/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_6_x86_64/",
                         "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"},
    "salt_migration_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64-BETA/"}
}

# 5.0 Server coming from
# https://build.suse.de/package/view_file/SUSE:SLE-15-SP5:Update:Products:Manager50/000product/SUSE-Manager-Server.product?expand=1
# line 25 + 71 with ":" changed to "_" 5.0 Proxy coming from
# https://build.suse.de/package/view_file/SUSE:SLE-15-SP5:Update:Products:Manager50/000product/SUSE-Manager-Proxy.product?expand=1
# line 25 + 71 with ":" changed to "_"
# Only product, we are extension not module anymore

# Dictionary for SUMA 5.0 Server and Proxy, which is then added together with
# the common dictionary for 4.3 client tools and 5.0 BETA client tools. Both
# client tools are needed until 5.0 gets its own client tools.
v50_nodes: Dict[str, Set[str]] = {
    "server": {"/SUSE_Products_SUSE-Manager-Server_5.0_x86_64/",
               "/SUSE_Updates_SUSE-Manager-Server_5.0_x86_64/"},
    "proxy": {"/SUSE_Products_SUSE-Manager-Proxy_5.0_x86_64/",
              "/SUSE_Updates_SUSE-Manager-Proxy_5.0_x86_64/",
              "/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/",
              "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
              "/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
              "/SUSE_Updates_SUSE-MicroOS_5.5_x86_64/",
              "/SUSE_Updates_SLE-Micro_5.5_x86_64/"}
}

def get_merged_client_tools(v43_client_tools: Dict[str, Set[str]]) -> Dict[str, Set[str]]:
    return {
        key: value.union(v50_client_tools_beta.get(key, set())) 
        for key, value in v43_client_tools.items()
    }

def get_v50_nodes_sorted(v43_client_tools: Dict[str, Set[str]]) -> Dict[str, List[str]]:
    merged_client_tools = get_merged_client_tools(v43_client_tools)
    v50_nodes.update(merged_client_tools)
    return {k: sorted(v) for k, v in v50_nodes.items()}