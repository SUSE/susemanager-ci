import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from functools import cache
import json
import os
import requests
from requests.adapters import HTTPAdapter
import logging
import sys
import threading
from urllib3.util.retry import Retry

from ibs_osc_client import IbsOscClient
from repository_versions import VersionNodes, nodes_by_version

IBS_MAINTENANCE_URL_PREFIX: str = 'http://download.suse.de/ibs/SUSE:/Maintenance:/'
IBS_URL_PREFIX: str = 'http://download.suse.de/ibs/SUSE:'
JSON_OUTPUT_FILE_NAME: str = 'custom_repositories.json'

SLE16_CLIENT_TOOLS_REPO_NAME: str = 'sles16_client_tools'

DEFAULT_MAX_WORKERS: int = 20

# A check that does not complete is not a missing repository, so every check is
# retried before its result is believed. 404 is the only answer from IBS that
# means the repository is absent.
REQUEST_CONNECT_TIMEOUT: float = 5
REQUEST_READ_TIMEOUT: float = 15
# requests per check, the first one included
REQUEST_ATTEMPTS: int = 3
REQUEST_RETRY_STATUS_CODES: frozenset[int] = frozenset({408, 429}) | frozenset(range(500, 600))

# The SLFO PullRequest existence probes answer faster, but retry the same
# statuses the same number of times
PROBE_CONNECT_TIMEOUT: float = 5
PROBE_READ_TIMEOUT: float = 10

def build_session() -> requests.Session:
    retry = Retry(
        total=REQUEST_ATTEMPTS - 1,
        connect=REQUEST_ATTEMPTS - 1,
        read=REQUEST_ATTEMPTS - 1,
        backoff_factor=0.5,
        status_forcelist=REQUEST_RETRY_STATUS_CODES,
        allowed_methods=frozenset({"GET"}),
    )
    adapter = HTTPAdapter(max_retries=retry)
    session = requests.Session()
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    return session

_SESSIONS = threading.local()

def get_session() -> requests.Session:
    """The calling thread's session - requests.Session is not thread-safe."""
    session: requests.Session | None = getattr(_SESSIONS, "session", None)
    if session is None:
        session = build_session()
        _SESSIONS.session = session
    return session

def setup_logging():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    # urllib3 warns once per retry, which buries the run under hundreds of lines
    # when IBS is slow; what never completed is reported at the end instead
    logging.getLogger("urllib3.connectionpool").setLevel(logging.ERROR)

def _slfo_pr_id(value: str) -> str:
    pr_ids = [pr_id.strip() for pr_id in value.split(",") if pr_id.strip()]
    if not pr_ids:
        raise argparse.ArgumentTypeError(
            f"invalid SLFO PullRequest id: {value!r} (must be a positive integer)"
        )
    for pr_id in pr_ids:
        if not (pr_id.isdigit() and int(pr_id) > 0):
            raise argparse.ArgumentTypeError(
                f"invalid SLFO PullRequest id: {pr_id!r} (must be a positive integer)"
            )
    return value

def parse_cli_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="This script reads the open qam-manager requests and creates a json file that can be fed to the BV testsuite pipeline"
    )
    parser.add_argument("-v", "--version", required=True, dest="version",
                        help="Version of SUMA/MLM to run this script for",
                        choices=list(nodes_by_version.keys()), action='store')
    parser.add_argument("-i", "--mi_ids", required=False, dest="mi_ids", help="Space separated list of MI IDs", nargs='*', action='store')
    parser.add_argument("-f", "--file", required=False, dest="file", help="Path to a file containing MI IDs separated by newline character", action='store')
    parser.add_argument("-e", "--no_embargo", dest="embargo_check", help="Reject MIs under embargo",  action='store_true')
    parser.add_argument(
        "-s", "--slfo-pull-request",
        required=False,
        dest="slfo_pull_requests",
        metavar="ID",
        nargs='+',
        type=_slfo_pr_id,
        help="Space separated list of SLFO PullRequest ids. Each id is looked up on IBS and applied where it belongs: "
             "MultiLinuxManagerTools PullRequests feed the SLE-16 client tools, Multi-Linux-Manager Packages "
             "PullRequests feed the server/proxy of the micro variant. Stable 51-* / 52-* only; rejected for "
             "*-beta versions (beta uses :ToTest automatically)",
    )

    if argv is None:
        argv = sys.argv[1:]
    # No arguments at all is not a misuse, it is somebody looking for the usage:
    # show the help instead of an error about the missing -v.
    if not argv:
        parser.print_help()
        raise SystemExit(0)

    args = parser.parse_args(argv)
    args.slfo_pull_requests = clean_slfo_pull_request_ids(args.slfo_pull_requests)
    if args.slfo_pull_requests:
        if not supports_slfo_pull_request(args.version):
            parser.error("--slfo-pull-request is only supported for 51-* and 52-* versions")
        if args.version.endswith("-beta"):
            parser.error("--slfo-pull-request is not supported for beta versions (beta uses :ToTest automatically)")
    return args

def clean_slfo_pull_request_ids(pr_ids: list[str] | None) -> list[str]:
    """Flatten '-s 370 65' and '-s 370,65' into a de-duplicated, ordered list of ids."""
    if not pr_ids:
        return []

    cleaned: list[str] = []
    for value in pr_ids:
        for pr_id in value.split(","):
            pr_id = pr_id.strip()
            if pr_id and pr_id not in cleaned:
                cleaned.append(pr_id)
    return cleaned

def read_mi_ids_from_file(file_path: str | os.PathLike[str]) -> list[str]:
    """Read newline-separated MI ids from a file (path may be str or pathlib.Path)."""
    with open(file_path, 'r', encoding='utf-8') as file:
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

    res: requests.Response = get_session().get(url, timeout=(REQUEST_CONNECT_TIMEOUT, REQUEST_READ_TIMEOUT))
    if 200 <= res.status_code < 300:
        return url
    if res.status_code == requests.codes.not_found:
        return ""
    raise requests.HTTPError(f"HTTP {res.status_code}", response=res)

def abort_on_unanswered_checks(unanswered: list[tuple[str, str]], output_file: str = JSON_OUTPUT_FILE_NAME):
    """An unanswered check is not an absent repository, so nothing is written."""
    if not unanswered:
        return

    for target, error in unanswered:
        logging.error(f"No answer for {target}: {error}")
    raise SystemExit(
        f"{len(unanswered)} of the repository checks never completed, so {output_file} was not written. "
        "Re-run once IBS is reachable."
    )

def validate_and_store_results(expected_ids: set [str], custom_repositories: dict[str, dict[str, str]], output_file: str = JSON_OUTPUT_FILE_NAME):
    if not custom_repositories:
        raise SystemExit("Empty custom_repositories dictionary, something went wrong")

    found_ids: set[str] = { id for custom_repo in custom_repositories.values() for id in custom_repo.keys() }
    # there should be no set difference if all MI IDs are in the JSON
    missing_ids: set[str] = expected_ids.difference(found_ids)
    if missing_ids:
        logging.warning(
            f"MI IDs {sorted(missing_ids)} have no repository in the final JSON, "
            "perhaps they are not for the version you are running the script for."
        )

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(custom_repositories, f, indent=2, sort_keys=True)

def get_version_nodes(version: str) -> VersionNodes:
    version_nodes = nodes_by_version.get(version)
    if version_nodes is None:
        supported_versions = ', '.join(nodes_by_version.keys())
        raise ValueError(f"No nodes for version {version} - supported versions: {supported_versions}")
    return version_nodes

def init_custom_repositories(static_repos: dict[str, dict[str, str]] | None = None) -> dict[str, dict[str, str]]:
    custom_repositories: dict[str, dict[str, str]] = {}

    # Merge static named repos (full http URLs or maintenance path fragments)
    if static_repos:
        for node, named_urls in static_repos.items():
            custom_repositories[node] = {
                name: f"{IBS_MAINTENANCE_URL_PREFIX}{url}" if not url.startswith("http") else url
                for name, url in named_urls.items()
            }
    return custom_repositories


def supports_slfo_pull_request(version: str) -> bool:
    return version.startswith(("51", "52"))


def is_micro_variant(version: str) -> bool:
    return version.endswith("-micro")


def mlm_product_version(version: str) -> str:
    """'52-micro' -> '5.2' - the product version as it appears in SLFO paths."""
    digits = version.split("-", 1)[0]
    return f"{digits[0]}.{digits[1:]}"


@cache
def probe_url(url: str) -> bool | None:
    """Whether an IBS path is published, None if IBS could not be reached."""
    for attempt in range(1, REQUEST_ATTEMPTS + 1):
        try:
            res: requests.Response = requests.get(url, timeout=(PROBE_CONNECT_TIMEOUT, PROBE_READ_TIMEOUT))
        except requests.RequestException as exc:
            logging.warning(f"Error checking {url} (attempt {attempt} of {REQUEST_ATTEMPTS}): {exc}")
            continue
        # only a 2xx says the path is published and only a 404 says it is absent
        if 200 <= res.status_code < 300:
            return True
        if res.status_code == requests.codes.not_found:
            return False
        # a status IBS will not answer differently on a retry is reported as
        # unanswered straight away
        if res.status_code not in REQUEST_RETRY_STATUS_CODES:
            logging.warning(f"Error checking {url}: HTTP {res.status_code}")
            return None
        logging.warning(f"Error checking {url} (attempt {attempt} of {REQUEST_ATTEMPTS}): HTTP {res.status_code}")

    return None


def url_exists(url: str) -> bool:
    """Whether an IBS path is published. An unreachable IBS stops the run."""
    published = probe_url(url)
    if published is None:
        raise SystemExit(f"IBS could not be reached to check {url}")
    return published

def slfo_pullrequest_client_tool_url(pr_id: str, arch: str = "x86_64") -> str:
    """Return the stable SLE-16 MultiLinuxManagerTools URL for the given PullRequest id and architecture.

    This URL is used for sles160_minion, slmicro62_minion (x86_64), and opensuse160arm_minion (aarch64).
    SL Micro 6.2 consumes the same SLE-16 client-tools repo on the stable PullRequest path.
    Beta client tools do not use PullRequest URLs - they are served from static
    :ToTest definitions in repository_versions/*_nodes.py.
    """
    root = "/SLFO:/Products:/MultiLinuxManagerTools:/PullRequest"
    tail = f":/{pr_id}:/SLES/product/repo/Multi-Linux-ManagerTools-SLE-16-{arch}/"
    return f"{IBS_URL_PREFIX}{root}{tail}"


def slfo_pullrequest_repo_key(pr_id: str, minion: str, arch: str) -> str:
    """Inner dict key for SLFO PullRequest client-tools repos (not an MI id).

    Args:
        pr_id: SLFO PullRequest id
        minion: Minion shortname (e.g. 'sles160', not 'sles160_minion')
        arch: Architecture (e.g. 'x86_64' or 'aarch64')

    Returns:
        Repository key in format: slfo_pr_{id}_{minion}_{arch}
    """
    return f"slfo_pr_{pr_id}_{minion}_{arch}"


def apply_slfo_pullrequest_client_tools(
    custom_repositories: dict[str, dict[str, str]], pr_id: str
) -> None:
    for node, arch in [
        ("sles160_minion", "x86_64"),
        ("slmicro62_minion", "x86_64"),
        ("opensuse160arm_minion", "aarch64"),
    ]:
        url = slfo_pullrequest_client_tool_url(pr_id, arch=arch)
        minion_shortname = node.removesuffix("_minion")
        # the PullRequest repo replaces the :ToTest one, it is not added to it
        custom_repositories.get(node, {}).pop(SLE16_CLIENT_TOOLS_REPO_NAME, None)
        update_custom_repositories(custom_repositories, node,
                                  slfo_pullrequest_repo_key(pr_id, minion_shortname, arch), url)


def mlm_packages_pullrequest_url(pr_id: str, product_version: str, repo: str) -> str:
    """Return the Multi-Linux-Manager Packages PullRequest URL for one product repo.

    Maintenance publishes the SL Micro server/proxy content of an open PullRequest
    under :Packages:/PullRequest:/<id>:/SL-Micro.
    """
    root = f"/SLFO:/Products:/Multi-Linux-Manager:/{product_version}:/Packages:/PullRequest"
    return f"{IBS_URL_PREFIX}{root}:/{pr_id}:/SL-Micro/product/repo/{repo}/"


def mlm_packages_pullrequest_repo_key(pr_id: str, repo_name: str) -> str:
    """Inner dict key for MLM Packages PullRequest repos (not an MI id)."""
    return f"slfo_pr_{pr_id}_{repo_name}"


def classify_slfo_pull_requests(pr_ids: list[str], version: str) -> dict[str, list[str]]:
    """Sort PullRequest ids into the family each one belongs to, by asking IBS.

    The families are numbered independently, an id can exist in one and not in
    the other. An id that exists in neither stops the run.
    """
    product_version = mlm_product_version(version)
    families: dict[str, list[str]] = {"client_tools": [], "mlm_packages": []}

    for pr_id in pr_ids:
        candidates: dict[str, str] = {
            "client_tools": slfo_pullrequest_client_tool_url(pr_id),
            "mlm_packages": mlm_packages_pullrequest_url(
                pr_id, product_version, f"Multi-Linux-Manager-Server-{product_version}-x86_64"
            ),
        }
        matches: list[str] = [family for family, url in candidates.items() if url_exists(url)]

        if not matches:
            probed = "\n  ".join(candidates.values())
            raise SystemExit(
                f"SLFO PullRequest id {pr_id} was not found on IBS. Probed:\n  {probed}"
            )
        if len(matches) > 1:
            raise SystemExit(
                f"SLFO PullRequest id {pr_id} exists in more than one project ({', '.join(matches)}), "
                "cannot tell which one you mean"
            )

        family = matches[0]
        families[family].append(pr_id)
        logging.info(f"SLFO PullRequest {pr_id} resolved as {family}")

    return families


def apply_mlm_packages_pullrequest(
    custom_repositories: dict[str, dict[str, str]], pr_id: str, version: str
) -> None:
    """Point server/proxy at a Packages PullRequest instead of the :ToTest repos."""
    product_version = mlm_product_version(version)
    repos_by_node: dict[str, dict[str, str]] = {
        "server": {"server_uyuni_tools": f"Multi-Linux-Manager-Server-{product_version}-x86_64"},
        "proxy": {
            "proxy_uyuni_tools": f"Multi-Linux-Manager-Proxy-{product_version}-x86_64",
            "retail_uyuni_tools": f"Multi-Linux-Manager-Retail-Branch-Server-{product_version}-x86_64",
        },
    }

    for node, repos in repos_by_node.items():
        for repo_name, repo in repos.items():
            url = mlm_packages_pullrequest_url(pr_id, product_version, repo)
            if not url_exists(url):
                raise SystemExit(
                    f"SLFO PullRequest {pr_id} does not publish {repo}, expected at {url}"
                )
            # the PullRequest repo replaces the :ToTest one, it is not added to it
            custom_repositories.get(node, {}).pop(repo_name, None)
            update_custom_repositories(
                custom_repositories, node, mlm_packages_pullrequest_repo_key(pr_id, repo_name), url
            )


def apply_slfo_pull_requests(
    custom_repositories: dict[str, dict[str, str]], pr_ids: list[str], version: str
) -> None:
    families = classify_slfo_pull_requests(pr_ids, version)

    for pr_id in families["client_tools"]:
        apply_slfo_pullrequest_client_tools(custom_repositories, pr_id)

    for pr_id in families["mlm_packages"]:
        if not is_micro_variant(version):
            # a Packages PullRequest only publishes SL Micro server/proxy repos
            logging.info(
                f"SLFO PullRequest {pr_id} only applies to the micro variant, skipping it for {version}"
            )
            continue
        apply_mlm_packages_pullrequest(custom_repositories, pr_id, version)


def warn_on_unresolved_uyuni_tools_repos(custom_repositories: dict[str, dict[str, str]]) -> None:
    """Warn about server/proxy repos that are still :ToTest but not published."""
    for node in ("server", "proxy"):
        for repo_name, url in custom_repositories.get(node, {}).items():
            if not (repo_name.endswith("_uyuni_tools") and "/ToTest/" in url):
                continue
            # probe_url instead of url_exists, a warning must never end the run
            published = probe_url(url)
            if published is False:
                logging.warning(f"{node}: {repo_name} does not exist on IBS: {url}")
            elif published is None:
                logging.warning(f"{node}: {repo_name} could not be checked on IBS: {url}")


def update_custom_repositories(custom_repositories: dict[str, dict[str, str]], node: str, mi_id: str, url: str):
    node_ids: dict[str, str] = custom_repositories.get(node, {})
    final_id: str = mi_id
    i: int = 1
    while final_id in node_ids:
        final_id = f"{mi_id}_{i}"
        i += 1
    node_ids[final_id] = url
    custom_repositories[node] = node_ids


def find_valid_repos(mi_ids: set[str], version: str, slfo_pull_request_ids: list[str] | None = None, max_workers: int = DEFAULT_MAX_WORKERS):
    """
    Find valid repository URLs for given MI IDs and version.

    Uses parallel HTTP requests to check repository existence.

    Args:
        mi_ids: Set of MI ID strings
        version: SUMA version (43, 50-sles, 51-sles, etc.)
        slfo_pull_request_ids: Optional SLFO PullRequest ids, each one looked up
            on IBS and applied to the nodes of the family it belongs to; only
            valid for stable 51-* / 52-* versions.
        max_workers: Number of concurrent HTTP requests (default: 20)
    """
    version_data = get_version_nodes(version)

    static_repos = version_data.get("static", {})
    dynamic_nodes = version_data.get("dynamic", {})

    custom_repositories = init_custom_repositories(static_repos)

    # Build a list of all (node, mi_id, repo) combinations to check
    tasks = []
    for node, repositories in dynamic_nodes.items():
        for mi_id in mi_ids:
            for repo in repositories:
                tasks.append((node, mi_id, repo))

    logging.info(f"Checking {len(tasks)} repository URLs in parallel (max_workers={max_workers})")

    # Execute HTTP requests in parallel
    lock = threading.Lock()
    found_count = 0
    unanswered: list[tuple[str, str]] = []

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Submit all tasks
        future_to_task = {
            executor.submit(create_url, mi_id, repo): (node, mi_id, repo)
            for node, mi_id, repo in tasks
        }

        # Collect results as they complete
        for future in as_completed(future_to_task):
            node, mi_id, repo = future_to_task[future]
            try:
                repo_url = future.result()
                if repo_url:
                    # Thread-safe update
                    with lock:
                        update_custom_repositories(custom_repositories, node, mi_id, repo_url)
                        found_count += 1
            except Exception as exc:
                with lock:
                    unanswered.append((f"{mi_id}{repo}", str(exc)))

    abort_on_unanswered_checks(unanswered)

    if slfo_pull_request_ids:
        if not supports_slfo_pull_request(version):
            raise ValueError(
                f"SLFO PullRequest id is only supported for 51-* and 52-* versions (got {version!r})"
            )
        if version.endswith("-beta"):
            raise ValueError(
                f"SLFO PullRequest id is not supported for beta versions (got {version!r}); beta uses :ToTest automatically"
            )
        apply_slfo_pull_requests(custom_repositories, slfo_pull_request_ids, version)

    warn_on_unresolved_uyuni_tools_repos(custom_repositories)

    logging.info(f"Found {found_count} valid repositories out of {len(tasks)} checked")
    validate_and_store_results(mi_ids, custom_repositories)

def main():
    setup_logging()
    args: argparse.Namespace = parse_cli_args()
    osc_client: IbsOscClient = IbsOscClient()

    # Warn if using placeholder beta versions
    if args.version in ("53-sles-beta", "53-micro-beta"):
        logging.warning("=" * 80)
        logging.warning("WARNING: 53-*-beta versions are PLACEHOLDERS and not yet ready for production!")
        logging.warning("URLs in v53_nodes.py need to be updated when 5.3 beta project is created.")
        logging.warning("The generated JSON may contain incorrect or non-existent repository URLs.")
        logging.warning("=" * 80)

    mi_ids: set[str] = merge_mi_ids(args)
    logging.info(f"MI IDs: {mi_ids}")
    if args.slfo_pull_requests:
        logging.info(f"SLFO PullRequest ids: {args.slfo_pull_requests}")
    if not mi_ids:
        mi_ids = osc_client.find_maintenance_incidents()

    if args.embargo_check:
        logging.info(f"Remove MIs under embargo")
        mi_ids = { id for id in mi_ids if not osc_client.mi_is_under_embargo(id) }

    find_valid_repos(mi_ids, args.version, args.slfo_pull_requests)

    logging.info("JSON file generated successfully: %s", JSON_OUTPUT_FILE_NAME)
    logging.info("You can open it with: cat %s", JSON_OUTPUT_FILE_NAME)

if __name__ == '__main__':
    main()
