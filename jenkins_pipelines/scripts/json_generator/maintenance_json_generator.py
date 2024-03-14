import argparse
from functools import cache
import json
import requests

from ibs_osc_client import IbsOscClient


IBS_MAINTENANCE_URL_PREFIX: str = 'http://download.suse.de/ibs/SUSE:/Maintenance:/'

# dictionary for 4.3 client tools
v43_client_tools: dict[str, set[str]] = {
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
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP5_x86_64/"},
    "sle15sp5_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP5_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP5_x86_64/"},
    "sle15sp5s390_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_s390x/",
                            "/SUSE_Updates_SLE-Module-Basesystem_15-SP5_s390x/",
                            "/SUSE_Updates_SLE-Module-Server-Applications_15-SP5_s390x/"},
    "centos7_client": {"/SUSE_Updates_RES_7-CLIENT-TOOLS_x86_64/"},
    "centos7_minion": {"/SUSE_Updates_RES_7-CLIENT-TOOLS_x86_64"},
    "rocky8_minion": {"/SUSE_Updates_RES_8-CLIENT-TOOLS_x86_64/"},
    "alma8_minion": {"/SUSE_Updates_RES_8-CLIENT-TOOLS_x86_64/"},
    "ubuntu2004_minion": {"/SUSE_Updates_Ubuntu_20.04-CLIENT-TOOLS_x86_64/"},
    "ubuntu2204_minion": {"/SUSE_Updates_Ubuntu_22.04-CLIENT-TOOLS_x86_64/"},
    "debian11_minion": {"/SUSE_Updates_Debian_11-CLIENT-TOOLS_x86_64/"},
    "debian12_minion": {"/SUSE_Updates_Debian_12-CLIENT-TOOLS_x86_64/"},
    "opensuse154arm_minion": {"/SUSE_Updates_openSUSE-SLE_15.4/",
                              "/SUSE_Updates_SLE-Manager-Tools_15_aarch64/"},
    "opensuse155arm_minion": {"/SUSE_Updates_openSUSE-SLE_15.5/",
                              "/SUSE_Updates_SLE-Manager-Tools_15_aarch64/"},
    "rhel9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/"},
    "rocky9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/"},
    "alma9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/"},
    "oracle9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/"},
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
    "salt_migration_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                              "/SUSE_Updates_SLE-Module-Basesystem_15-SP5_x86_64/",
                              "/SUSE_Updates_SLE-Module-Server-Applications_15-SP5_x86_64/"},
}

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
    "sle15sp5s390_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_s390x/"},
    "centos7_client": {"/SUSE_Updates_RES_7-CLIENT-TOOLS-BETA_x86_64/"},
    "centos7_minion": {"/SUSE_Updates_RES_7-CLIENT-TOOLS-BETA_x86_64"},
    "rocky8_minion": {"/SUSE_Updates_RES_8-CLIENT-TOOLS-BETA_x86_64/"},
    "alma8_minion": {"/SUSE_Updates_RES_8-CLIENT-TOOLS-BETA_x86_64/"},
    "ubuntu2004_minion": {"/SUSE_Updates_Ubuntu_20.04-CLIENT-TOOLS-BETA_x86_64/"},
    "ubuntu2204_minion": {"/SUSE_Updates_Ubuntu_22.04-CLIENT-TOOLS-BETA_x86_64/"},
    "debian11_minion": {"/SUSE_Updates_Debian_11-CLIENT-TOOLS-BETA_x86_64/"},
    "debian12_minion": {"/SUSE_Updates_Debian_12-CLIENT-TOOLS-BETA_x86_64/"},
    "opensuse154arm_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_aarch64/"},
    "opensuse155arm_minion": {"/SUSE_Updates_SLE-Manager-Tools_15-BETA_aarch64/"},
    "rhel9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/"},
    "rocky9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/"},
    "alma9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/"},
    "oracle9_minion": {"/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/"},
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
    "salt_migration_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64-BETA/"}
}

# Merging v43_client_tools and v50_client_tools_beta
# For now we need non-BETA together with BETA client tools until the split
# between 4.3 and 5.0 for client tools happens, just before GA
# After the split the 5.0 non-BETA client tools will have different names than
# the 4.3 non-BETA client tools. They will not be common.
merged_client_tools: dict[str, set[str]] = {
    key: value.union(v50_client_tools_beta.get(key, set())) for key, value in v43_client_tools.items()
}

# Dictionary for SUMA 4.3 Server and Proxy, which is then added together with the common dictionary for 4.3 client tools
v43_nodes: dict[str, set[str]] = {
    "server": {"/SUSE_Updates_SLE-Module-SUSE-Manager-Server_4.3_x86_64/",
               "/SUSE_Updates_SLE-Product-SUSE-Manager-Server_4.3_x86_64/",
               "/SUSE_Updates_SLE-Module-Basesystem_15-SP4_x86_64/",
               "/SUSE_Updates_SLE-Module-Web-Scripting_15-SP4_x86_64/",
               "/SUSE_Updates_SLE-Module-Server-Applications_15-SP4_x86_64/"},
    "proxy": {"/SUSE_Updates_SLE-Module-SUSE-Manager-Proxy_4.3_x86_64/",
              "/SUSE_Updates_SLE-Product-SUSE-Manager-Proxy_4.3_x86_64/",
              "/SUSE_Updates_SLE-Module-Basesystem_15-SP4_x86_64/",
              "/SUSE_Updates_SLE-Module-Server-Applications_15-SP4_x86_64/"}
}
v43_nodes.update(v43_client_tools)

# 5.0 Server coming from
# https://build.suse.de/package/view_file/SUSE:SLE-15-SP5:Update:Products:Manager50/000product/SUSE-Manager-Server.product?expand=1
# line 25 + 71 with ":" changed to "_" 5.0 Proxy coming from
# https://build.suse.de/package/view_file/SUSE:SLE-15-SP5:Update:Products:Manager50/000product/SUSE-Manager-Proxy.product?expand=1
# line 25 + 71 with ":" changed to "_"
# Only product, we are extension not module anymore

# Dictionary for SUMA 5.0 Server and Proxy, which is then added together with
# the common dictionary for 4.3 client tools and 5.0 BETA client tools. Both
# client tools are needed until 5.0 gets its own client tools.
v50_nodes: dict[str, set[str]] = {
    "server": {"/SUSE_Products_SUSE-Manager-Server_5.0_x86_64/",
               "/SUSE_Updates_SUSE-Manager-Server_5.0_x86_64/"},
    "proxy": {"/SUSE_Products_SUSE-Manager-Proxy_5.0_x86_64/",
              "/SUSE_Updates_SUSE-Manager-Proxy_5.0_x86_64/"}
}
v50_nodes.update(merged_client_tools)

nodes_by_version: dict[str, dict[str, set[str]]] = {
    "43": v43_nodes,
    "50": v50_nodes
}

def parse_cli_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="This script reads the open qam-manager requests and creates a json file that can be fed to the BV testsuite pipeline"
    )
    parser.add_argument("-v", "--version", dest="version",
        help="Version of SUMA you want to run this script for, the options are 43 for 4.3 and 50 for 5.0. The default is 43 for now",
        choices=["43", "50"], default="43", action='store', 
    )
    parser.add_argument("-i", "--mi_ids", required=False, dest="mi_ids", help="Space separated list of MI IDs", nargs='*', action='store')
    parser.add_argument("-e", "--no_embargo", dest="embargo_check", help="Reject MIs under embargo",  action='store_true')

    args: argparse.Namespace = parser.parse_args()
    return args

@cache
def create_url(mi_id:str, suffix: str) -> str:
    url = f"{IBS_MAINTENANCE_URL_PREFIX}{mi_id}{suffix}"

    res: requests.Response = requests.get(url)
    if res.ok:
        return url
    return ""

def find_valid_repos(mi_ids: set[str], version: str):
    version_nodes: dict[str, dict[str, set[str]]] = nodes_by_version.get(version, None)
    if not version_nodes:
        raise SystemExit(f"No nodes for version {version} - supported versions: {nodes_by_version.keys()}")

    custom_repositories: dict[str, dict[str, str]] = {}
    if version == '50':
        # TODO Remove the following hardcoding at GA, we should start getting MIs for server and proxy
        # Add exception for specific URL for "server" and "proxy" nodes in version 5.0
        # Hardcoded URLs for "server" and "proxy" nodes until we get MIs with them
        server_url = "http://download.suse.de/ibs/SUSE:/SLE-15-SP5:/Update:/Products:/Manager50/images/repo/SUSE-Manager-Server-5.0-POOL-x86_64-Media1/"
        proxy_url = "http://download.suse.de/ibs/SUSE:/SLE-15-SP5:/Update:/Products:/Manager50/images/repo/SUSE-Manager-Proxy-5.0-POOL-x86_64-Media1/"
        custom_repositories['server'] = {'server_50': server_url}
        custom_repositories['proxy'] = {'proxy_50': proxy_url}

    for node, suffixraw in version_nodes.items():
        for mi_id in mi_ids:
            for suffix in suffixraw:
                repo: str = create_url(mi_id, suffix)
                if repo:
                    if node in custom_repositories:
                        # This is needed for mi_ids that have multiple repos for each node
                        # e.g. basesystem and server apps for server
                        final_id = mi_id
                        if final_id in custom_repositories[node]:
                            for i in range(1, 100):
                                new_id = f"{mi_id}-{i}" 
                                if new_id not in custom_repositories[node]:
                                    final_id = new_id
                                    break
                        # for each mi_id we have multiple repos sometimes for each node
                        custom_repositories[node][final_id] = repo
                    else:
                        custom_repositories[node] = {mi_id: repo}

    # Format into json and print
    # Check that it's not empty and save to file
    if not custom_repositories:
        raise SystemExit("Empty custom_repositories dictionary, something went wrong")

    with open('custom_repositories.json', 'w', encoding='utf-8') as f:
        json.dump(custom_repositories, f, indent=2)

def main():
    args: argparse.Namespace = parse_cli_args()
    osc_client: IbsOscClient = IbsOscClient()

    mi_ids: set[str] = args.mi_ids
    if not mi_ids:
        mi_ids = osc_client.find_maintenance_incidents()

    if args.embargo_check:
        mi_ids = { id for id in mi_ids if not osc_client.mi_is_under_embargo(id) }

    find_valid_repos(mi_ids, args.version)

if __name__ == '__main__':
    main()
