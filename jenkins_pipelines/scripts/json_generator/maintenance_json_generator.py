import argparse
from functools import cache
import json
import requests
import logging
import re

from ibs_osc_client import IbsOscClient
from repository_versions import nodes_by_version

IBS_MAINTENANCE_URL_PREFIX: str = 'http://download.suse.de/ibs/SUSE:/Maintenance:/'
JSON_OUTPUT_FILE_NAME: str = 'custom_repositories.json'

def setup_logging():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def parse_cli_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="This script reads the open qam-manager requests and creates a json file that can be fed to the BV testsuite pipeline"
    )
    parser.add_argument("-v", "--version", dest="version",
                        help="Version of SUMA you want to run this script for, the options are 43 for 4.3, 50 for 5.0, and 51 for 5.1",
                        choices=["43", "50-micro", "50-sles", "51-micro","51-sles"], default="43", action='store')
    parser.add_argument("-i", "--mi_ids", required=False, dest="mi_ids", help="Space separated list of MI IDs", nargs='*', action='store')
    parser.add_argument("-f", "--file", required=False, dest="file", help="Path to a file containing MI IDs separated by newline character", action='store')
    parser.add_argument("-e", "--no_embargo", dest="embargo_check", help="Reject MIs under embargo",  action='store_true')
    return parser.parse_args()

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
    """
    Build the maintenance URL for the given MI and suffix, request it and try to
    detect whether the page/directory contains a .repo file. If a .repo is found
    return the directory URL (not the .repo file URL). Otherwise log an error, but still including it.
    """
    url = f"{IBS_MAINTENANCE_URL_PREFIX}{mi_id}{suffix}"

    try:
        res: requests.Response = requests.get(url, timeout=6)
    except requests.RequestException:
        logging.error(f"Error requesting: {url};")

    if not res.ok:
        logging.error(f"Error requesting: {url};")

    body = res.text or ""

    # If the URL itself points directly to a .repo file, consider the parent directory a valid repo URL.
    if url.lower().endswith('.repo'):
        # return parent directory (ensure trailing slash)
        parent = url.rsplit('/', 1)[0] + '/'
        return parent

    # Search the response body for links or references to .repo files.
    # First try to find href="...*.repo" or href='...*.repo'
    href_repo_re = re.compile(r'href=["\'](?P<link>[^"\']+?\.repo)\b["\']', re.IGNORECASE)
    m = href_repo_re.search(body)
    repo_candidate = None
    if m:
        repo_candidate = m.group('link')
    else:
        # Fall back to any occurrence of a token ending in .repo (plain text listings)
        token_repo_re = re.compile(r'(?P<link>https?://[^\s"\'<>]+?\.repo\b)|(?P<link2>[^\s"\'<>]+?\.repo\b)', re.IGNORECASE)
        m2 = token_repo_re.search(body)
        if m2:
            repo_candidate = m2.group('link') or m2.group('link2')

    if not repo_candidate:
        logging.error(f"No .repo reference found at {url}; That might be a Debian-Like repo.")

    # We found at least one .repo reference on the page, consider the directory valid and return the directory URL.
    return url

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

def init_custom_repositories(version: str, static_repos: dict[str, dict[str, str]] = None) -> dict[str, dict[str, str]]:
    custom_repositories: dict[str, dict[str, str]] = {}
    if version.startswith("51") and static_repos:
        for node, named_urls in static_repos.items():
            custom_repositories[node] = {
                name: f"{IBS_MAINTENANCE_URL_PREFIX}{url}" if not url.startswith("http") else url
                for name, url in named_urls.items()
            }
    return custom_repositories

def update_custom_repositories(custom_repositories: dict[str, dict[str, str]], node: str, mi_id: str, url: str):
    node_ids: dict[str, str] = custom_repositories.get(node, {})
    final_id: str = mi_id
    i: int = 1
    while final_id in node_ids:
        final_id = f"{mi_id}-{i}"
        i += 1
    node_ids[final_id] = url
    custom_repositories[node] = node_ids


def find_valid_repos(mi_ids: set[str], version: str):
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