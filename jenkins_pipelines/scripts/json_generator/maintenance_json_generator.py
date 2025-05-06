import argparse
from functools import cache
import json
import requests
import logging

from ibs_osc_client import IbsOscClient


IBS_MAINTENANCE_URL_PREFIX: str = 'http://download.suse.de/ibs/SUSE:/Maintenance:/'
JSON_OUTPUT_FILE_NAME: str = 'custom_repositories.json'

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
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP6_x86_64/"},
    "sle15sp7_client": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP7_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP7_x86_64/"},
    "sle15sp7_minion": {"/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP7_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP7_x86_64/"},
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
              "/SUSE_Updates_SUSE-Manager-Proxy_5.0_x86_64/",
              "/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/",
              "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
              "/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
              "/SUSE_Updates_SUSE-MicroOS_5.5_x86_64/",
              "/SUSE_Updates_SLE-Micro_5.5_x86_64/"},
}
v50_nodes.update(merged_client_tools)

v43_nodes_sorted: dict[str, list[str]] = {k:sorted(v) for k,v in v43_nodes.items()}
v50_nodes_sorted: dict[str, list[str]] = {k:sorted(v) for k,v in v50_nodes.items()}

nodes_by_version: dict[str, dict[str, list[str]]] = {
    "43": v43_nodes_sorted,
    "50": v50_nodes_sorted
}

def setup_logging():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def parse_cli_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="This script reads the open qam-manager requests and creates a json file that can be fed to the BV testsuite pipeline"
    )
    parser.add_argument("-v", "--version", dest="version",
        help="Version of SUMA you want to run this script for, the options are 43 for 4.3 and 50 for 5.0. The default is 43 for now",
        choices=["43", "50"], default="43", action='store',
    )
    parser.add_argument("-i", "--mi_ids", required=False, dest="mi_ids", help="Space separated list of MI IDs", nargs='*', action='store')
    parser.add_argument("-f", "--file", required=False, dest="file", help="Path to a file containing MI IDs separated by newline character", action='store')
    parser.add_argument("-e", "--no_embargo", dest="embargo_check", help="Reject MIs under embargo",  action='store_true')
    args: argparse.Namespace = parser.parse_args()
    return args

def read_mi_ids_from_file(file_path: str) -> list[str]:
    with open(file_path, 'r') as file:
        return file.read().strip().split()

def merge_mi_ids(args: argparse.Namespace) -> set[str]:
    mi_ids: set[str] = clean_mi_ids(args.mi_ids) if args.mi_ids else set()
    if args.file:
        file_mi_ids: set[str] = set(read_mi_ids_from_file(args.file))
        mi_ids.update(file_mi_ids)

    return mi_ids

def clean_mi_ids(mi_ids: list[str]) -> set[str]:
    # support 1234,4567,8901 format
    if(len(mi_ids) == 1):
        return { id.strip() for id in mi_ids[0].split(",") }
    # support 1234, 4567, 8901 format
    return { id.replace(',', '') for id in mi_ids }

@cache
def create_url(mi_id:str, suffix: str) -> str:
    url = f"{IBS_MAINTENANCE_URL_PREFIX}{mi_id}{suffix}"

    res: requests.Response = requests.get(url)
    if res.ok:
        return url
    return ""

def validate_and_store_results(expected_ids: set [str], custom_repositories: dict[str, dict[str, str]], output_file: str = JSON_OUTPUT_FILE_NAME):
    if not custom_repositories:
        raise SystemExit("Empty custom_repositories dictionary, something went wrong")

    found_ids: set[str] = { id for custom_repo in custom_repositories.values() for id in custom_repo.keys() }
    # there should be no set difference if all MI IDs are in the JSON
    missing_ids: set[str] = expected_ids.difference(found_ids)
    if missing_ids:
        logging.error(f"MI IDs #{missing_ids} do not exist in custom_repositories dictionary.")

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(custom_repositories, f, indent=2, sort_keys=True)

def get_version_nodes(version: str) -> dict[str, list[str]]:
    version_nodes: dict[str, list[str]] = nodes_by_version.get(version)
    if not version_nodes:
        supported_versions = ', '.join(nodes_by_version.keys())
        raise ValueError(f"No nodes for version {version} - supported versions: {supported_versions}")
    return version_nodes

def init_custom_repositories(version: str) -> dict[str, dict[str, str]]:
    custom_repositories = {}
    custom_repositories['slmicro60_minion'] = { 'alp_staging' : "http://download.suse.de/ibs/SUSE:/ALP:/Source:/Standard:/1.0:/Staging:/Z/images/repo/SL-Micro-6.0-x86_64/", 'alp_slfo_common_tools' : "http://download.suse.de/ibs/SUSE:/ALP:/Source:/Standard:/1.0:/Staging:/Z/images/repo/SUSE-Manager-Tools-For-SL-Micro-6-x86_64/" }
    custom_repositories['slmicro61_minion'] = { 'slfo_staging' : "http://download.suse.de/ibs/SUSE:/SLFO:/1.1:/Staging:/I/images/repo/SL-Micro-6.1-x86_64/", 'alp_slfo_common_tools' : "http://download.suse.de/ibs/SUSE:/ALP:/Source:/Standard:/1.0:/Staging:/Z/images/repo/SUSE-Manager-Tools-For-SL-Micro-6-x86_64/" }
    return custom_repositories

def update_custom_repositories(custom_repositories: dict[str, dict[str, str]], node: str, mi_id: str, url: str):
    node_ids: dict[str, str] = custom_repositories.get(node, None)
    if node_ids:
        # This is needed for mi_ids that have multiple repos for each node
        # e.g. basesystem and server apps for server
        final_id: str = mi_id
        i: int = 1
        while(final_id in node_ids):
            final_id = f"{mi_id}-{i}"
            i += 1
        # for each mi_id we have multiple repos sometimes for each node
        node_ids[final_id] = url
    else:
        custom_repositories[node] = {mi_id: url}

def find_valid_repos(mi_ids: set[str], version: str):
    version_nodes: dict[str, list[str]] = get_version_nodes(version)
    custom_repositories: dict[str, dict[str, str]] = init_custom_repositories(version)

    for node, repositories in version_nodes.items():
        for mi_id in mi_ids:
            for repo in repositories:
                repo_url: str = create_url(mi_id, repo)
                if repo_url:
                    update_custom_repositories(custom_repositories, node, mi_id, repo_url)

    validate_and_store_results(mi_ids, custom_repositories)

def main():
    setup_logging()
    args: argparse.Namespace = parse_cli_args()
    osc_client: IbsOscClient = IbsOscClient()

    mi_ids: set[str] = merge_mi_ids(args)
    logging.info(f"MI IDs: {mi_ids}")
    if not mi_ids:
        mi_ids = osc_client.find_maintenance_incidents()

    if args.embargo_check:
        logging.info(f"Remove MIs under embargo")
        mi_ids = { id for id in mi_ids if not osc_client.mi_is_under_embargo(id) }

    find_valid_repos(mi_ids, args.version)

if __name__ == '__main__':
    main()
