import argparse
from functools import cache
import json
import requests
import logging

from ibs_osc_client import IbsOscClient
from repository_versions import nodes_by_version

IBS_MAINTENANCE_URL_PREFIX: str = 'http://download.suse.de/ibs/SUSE:/Maintenance:/'
IBS_URL_PREFIX: str = 'http://download.suse.de/ibs/SUSE:'
JSON_OUTPUT_FILE_NAME: str = 'custom_repositories.json'
SUPPORTED_VERSIONS: list[str] = [
    "43",
    "50-micro",
    "50-sles",
    "51-micro",
    "51-sles",
    "52-micro",
    "52-sles",
    "52-micro-beta",
    "52-sles-beta",
]

def setup_logging():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def parse_cli_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="This script reads the open qam-manager requests and creates a json file that can be fed to the BV testsuite pipeline"
    )
    parser.add_argument("-v", "--version", dest="version",
                        help="Version of SUMA/MLM to run this script for. Accepted values: 43, 50-micro, 50-sles, 51-micro, 51-sles, 52-micro, 52-sles, 52-micro-beta, 52-sles-beta. Default: 51-sles.",
                        choices=SUPPORTED_VERSIONS, default="51-sles", action='store')
    parser.add_argument("-i", "--mi_ids", required=False, dest="mi_ids", help="Space separated list of MI IDs", nargs='*', action='store')
    parser.add_argument("-f", "--file", required=False, dest="file", help="Path to a file containing MI IDs separated by newline character", action='store')
    parser.add_argument("-e", "--no_embargo", dest="embargo_check", help="Reject MIs under embargo",  action='store_true')
    parser.add_argument(
        "--slfo-pull-request",
        required=False,
        dest="slfo_pull_request",
        metavar="ID",
        help="SLFO PullRequest id for sles160_minion and slmicro62_minion (5.1 / 5.2 only; independent of MI ids)",
    )
    args = parser.parse_args()
    if args.slfo_pull_request and not supports_slfo_pull_request(args.version):
        parser.error("--slfo-pull-request is only supported for 51-* and 52-* versions")
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
def create_url(mi_id: str, suffix: str) -> str:
    url = f"{IBS_MAINTENANCE_URL_PREFIX}{mi_id}{suffix}"

    res: requests.Response = requests.get(url, timeout=(3, 6))
    return url if res.ok else ""

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

def get_version_nodes(version: str):
    version_nodes = nodes_by_version.get(version)
    if not version_nodes:
        supported_versions = ', '.join(nodes_by_version.keys())
        raise ValueError(f"No nodes for version {version} - supported versions: {supported_versions}")
    return version_nodes

def init_custom_repositories(version: str, static_repos: dict[str, dict[str, str]] | None = None) -> dict[str, dict[str, str]]:
    custom_repositories: dict[str, dict[str, str]] = {}

    # SUMA 4.3 / 5.0 / 5.1 / 5.2: merge static named repos (full http URLs or maintenance path fragments)
    if static_repos and (
        version == "43"
        or version.startswith("50")
        or version.startswith("51")
        or version.startswith("52")
    ):
        for node, named_urls in static_repos.items():
            custom_repositories[node] = {
                name: f"{IBS_MAINTENANCE_URL_PREFIX}{url}" if not url.startswith("http") else url
                for name, url in named_urls.items()
            }
    return custom_repositories


def supports_slfo_pull_request(version: str) -> bool:
    return version.startswith("51") or version.startswith("52")

def slfo_pullrequest_client_tool_urls(pr_id: str, beta: bool) -> tuple[str, str]:
    """Return (sles160 tools URL, slmicro62 tools URL) for the given PullRequest id."""
    if beta:
        root = "/SLFO:/Products:/MultiLinuxManagerTools-Beta:/PullRequest"
        sle_tail = f":/{pr_id}:/SLES/product/repo/Multi-Linux-ManagerTools-Beta-SLE-16-x86_64/"
        micro_tail = f":/{pr_id}:/SL-Micro-6/product/repo/Multi-Linux-ManagerTools-Beta-SL-Micro-6-x86_64/"
    else:
        root = "/SLFO:/Products:/MultiLinuxManagerTools:/PullRequest"
        sle_tail = f":/{pr_id}:/SLES/product/repo/Multi-Linux-ManagerTools-SLE-16-x86_64/"
        micro_tail = f":/{pr_id}:/SL-Micro-6/product/repo/Multi-Linux-ManagerTools-SL-Micro-6-x86_64/"
    return (
        f"{IBS_URL_PREFIX}{root}{sle_tail}",
        f"{IBS_URL_PREFIX}{root}{micro_tail}",
    )


def apply_slfo_pullrequest_client_tools(
    custom_repositories: dict[str, dict[str, str]], version: str, pr_id: str
) -> None:
    beta = version.endswith("-beta")
    url_sle16, url_slmicro62 = slfo_pullrequest_client_tool_urls(pr_id, beta)
    update_custom_repositories(custom_repositories, "sles160_minion", pr_id, url_sle16)
    update_custom_repositories(custom_repositories, "slmicro62_minion", pr_id, url_slmicro62)


def update_custom_repositories(custom_repositories: dict[str, dict[str, str]], node: str, mi_id: str, url: str):
    node_ids: dict[str, str] = custom_repositories.get(node, {})
    final_id: str = mi_id
    i: int = 1
    while final_id in node_ids:
        final_id = f"{mi_id}_{i}"
        i += 1
    node_ids[final_id] = url
    custom_repositories[node] = node_ids


def find_valid_repos(mi_ids: set[str], version: str, slfo_pull_request_id: str | None = None):
    version_data = get_version_nodes(version)

    static_repos = version_data.get("static", {})
    dynamic_nodes = version_data.get("dynamic", {})

    custom_repositories = init_custom_repositories(version, static_repos)

    for node, repositories in dynamic_nodes.items():
        for mi_id in mi_ids:
            for repo in repositories:
                repo_url: str = create_url(mi_id, repo)
                if repo_url:
                    update_custom_repositories(custom_repositories, node, mi_id, repo_url)

    if slfo_pull_request_id:
        apply_slfo_pullrequest_client_tools(custom_repositories, version, slfo_pull_request_id)

    validate_and_store_results(mi_ids, custom_repositories)

def main():
    setup_logging()
    args: argparse.Namespace = parse_cli_args()
    osc_client: IbsOscClient = IbsOscClient()

    mi_ids: set[str] = merge_mi_ids(args)
    logging.info(f"MI IDs: {mi_ids}")
    if args.slfo_pull_request:
        logging.info(f"SLFO PullRequest id: {args.slfo_pull_request}")
    if not mi_ids:
        mi_ids = osc_client.find_maintenance_incidents()

    if args.embargo_check:
        logging.info(f"Remove MIs under embargo")
        mi_ids = { id for id in mi_ids if not osc_client.mi_is_under_embargo(id) }

    find_valid_repos(mi_ids, args.version, args.slfo_pull_request)

if __name__ == '__main__':
    main()
