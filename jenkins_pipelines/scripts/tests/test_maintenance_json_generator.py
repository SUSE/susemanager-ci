from argparse import Namespace
from contextlib import redirect_stderr, redirect_stdout
from http.server import BaseHTTPRequestHandler, HTTPServer
import io
import json
from os import path, remove
from pathlib import Path
import socket
import sys
import threading
import unittest
from unittest.mock import patch

from json_generator.maintenance_json_generator import *
from repository_versions.v43_nodes import v43_static_slmicro_salt_repositories
from repository_versions.v51_nodes import get_v51_static_and_client_tools
from repository_versions.v52_nodes import get_v52_static_and_client_tools
from repository_versions.v53_nodes import get_v53_static_and_client_tools
from tests.mock_response import MockResponse, mock_requests_get_success

TESTDATA_DIR = Path(__file__).resolve().parent / 'testdata'

CLIENT_TOOLS_PR_PROJECT = '/MultiLinuxManagerTools:/PullRequest:/'
MLM_PACKAGES_PR_PROJECT = ':/Packages:/PullRequest:/'


def _only_client_tools_exist(url: str) -> bool:
    """Stand in for IBS: only the MultiLinuxManagerTools PullRequest project is published."""
    return CLIENT_TOOLS_PR_PROJECT in url


def _only_mlm_packages_exist(url: str) -> bool:
    """Stand in for IBS: only the Multi-Linux-Manager Packages PullRequest project is published."""
    return MLM_PACKAGES_PR_PROJECT in url


class _StatusSequenceServer:
    """Stand in for IBS: answers the given status codes in order, repeating the last one."""

    def __init__(self, statuses: list[int]):
        self.requests: int = 0
        remaining: list[int] = list(statuses)
        server = self

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                server.requests += 1
                self.send_response(remaining.pop(0) if remaining else statuses[-1])
                self.send_header('Content-Length', '0')
                self.end_headers()

            def log_message(self, *_args):
                pass

        self._httpd = HTTPServer(('127.0.0.1', 0), Handler)
        self.url: str = f"http://127.0.0.1:{self._httpd.server_port}/repo/"

    def __enter__(self):
        self._thread = threading.Thread(target=self._httpd.serve_forever, daemon=True)
        self._thread.start()
        return self

    def __exit__(self, *_exc):
        self._httpd.shutdown()
        self._httpd.server_close()
        self._thread.join()


class _ConnectionDroppingServer:
    """Stand in for a broken network: closes the first `drops` connections unanswered."""

    def __init__(self, drops: int):
        self.connections: int = 0
        self._drops = drops
        self._sock = socket.socket()
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._sock.bind(('127.0.0.1', 0))
        self._sock.listen(16)
        self._sock.settimeout(0.1)
        self.url: str = f"http://127.0.0.1:{self._sock.getsockname()[1]}/repo/"

    def _serve(self):
        while not self._stop.is_set():
            try:
                conn, _addr = self._sock.accept()
            except (OSError, TimeoutError):
                continue
            self.connections += 1
            with conn:
                if self.connections <= self._drops:
                    continue
                conn.settimeout(5)
                conn.recv(4096)
                conn.sendall(b"HTTP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n")

    def __enter__(self):
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._serve, daemon=True)
        self._thread.start()
        return self

    def __exit__(self, *_exc):
        self._stop.set()
        self._thread.join()
        self._sock.close()


def _session_without_backoff() -> requests.Session:
    """The session under test, with the retry waits removed so the tests stay fast."""
    session = build_session()
    for adapter in session.adapters.values():
        adapter.max_retries = adapter.max_retries.new(backoff_factor=0)
    return session

class MaintenanceJsonGeneratorTestCase(unittest.TestCase):

    def test_parse_cli_args_default_values(self):
        sys.argv = ['maintenance_json_generator.py', '-v', '51-sles']
        args = parse_cli_args()
        self.assertEqual(args.version, "51-sles")
        self.assertIsNone(args.mi_ids)
        self.assertFalse(args.embargo_check)
        self.assertListEqual(args.slfo_pull_requests, [])

    def test_parse_cli_args_without_arguments_shows_help(self):
        sys.argv = ['maintenance_json_generator.py']
        stdout = io.StringIO()
        with redirect_stdout(stdout):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 0)
        self.assertIn("usage: maintenance_json_generator.py", stdout.getvalue())

    def test_parse_cli_args_version_is_mandatory(self):
        sys.argv = ['maintenance_json_generator.py', '-i', '1234']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("the following arguments are required: -v/--version", stderr.getvalue())

    def test_parse_cli_args_success(self):
        # shorthand flags
        sys.argv = ['maintenance_json_generator.py', '-v', '50-micro', '-i', '1234', '5678', '-e']
        args: Namespace = parse_cli_args()
        self.assertEqual(args.version, "50-micro")
        self.assertListEqual(args.mi_ids, ['1234', '5678'])
        self.assertTrue(args.embargo_check)
        # shorthand flags - mi_ids variant 1
        sys.argv = ['maintenance_json_generator.py', '-v', '50-micro', '-i', '1234,5678', '-f', 'some_file', '-e']
        args: Namespace = parse_cli_args()
        self.assertEqual(args.version, "50-micro")
        self.assertListEqual(args.mi_ids, ['1234,5678'])
        self.assertEqual(args.file, 'some_file')
        self.assertTrue(args.embargo_check)
        # shorthand flags - mi_ids variant 2
        sys.argv = ['maintenance_json_generator.py', '-v', '50-micro', '-i', '1234,', '5678', '-f', 'some_file', '-e']
        args: Namespace = parse_cli_args()
        self.assertEqual(args.version, "50-micro")
        self.assertListEqual(args.mi_ids, ['1234,' , '5678'])
        self.assertEqual(args.file, 'some_file')
        self.assertTrue(args.embargo_check)
        # long flags
        sys.argv = ['maintenance_json_generator.py', '--version', '50-micro', '--mi_ids', '1234', '5678', '--file', 'some_file', '--no_embargo']
        args: Namespace = parse_cli_args()
        self.assertEqual(args.version, "50-micro")
        self.assertListEqual(args.mi_ids, ['1234', '5678'])
        self.assertEqual(args.file, 'some_file')
        self.assertTrue(args.embargo_check)
        # doubly defined -i flag
        sys.argv = ['maintenance_json_generator.py', '-v', '50-micro', '-i', '9012', '3456' , '-f', 'some_file', '-i', '1234', '5678', '-e']
        args: Namespace = parse_cli_args()
        self.assertEqual(args.version, "50-micro")
        self.assertListEqual(args.mi_ids, ['1234', '5678'])
        self.assertEqual(args.file, 'some_file')
        self.assertTrue(args.embargo_check)
        # supported SLFO PullRequest flag
        sys.argv = ['maintenance_json_generator.py', '--version', '51-sles', '--slfo-pull-request', '9999']
        args = parse_cli_args()
        self.assertEqual(args.version, '51-sles')
        self.assertListEqual(args.slfo_pull_requests, ['9999'])
        # -s is the shorthand of --slfo-pull-request
        sys.argv = ['maintenance_json_generator.py', '-v', '52-sles', '-s', '9999']
        args = parse_cli_args()
        self.assertEqual(args.version, '52-sles')
        self.assertListEqual(args.slfo_pull_requests, ['9999'])
        # several ids, space separated and comma separated, deduplicated
        sys.argv = ['maintenance_json_generator.py', '-v', '52-micro', '-s', '370', '65']
        args = parse_cli_args()
        self.assertListEqual(args.slfo_pull_requests, ['370', '65'])
        sys.argv = ['maintenance_json_generator.py', '-v', '52-micro', '-s', '370,65']
        args = parse_cli_args()
        self.assertListEqual(args.slfo_pull_requests, ['370', '65'])
        sys.argv = ['maintenance_json_generator.py', '-v', '52-micro', '-s', '370,', '65', '370']
        args = parse_cli_args()
        self.assertListEqual(args.slfo_pull_requests, ['370', '65'])

    def test_parse_cli_args_failure(self):
        sys.argv = ['maintenance_json_generator.py',  '-v', '51-sles', '-x']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("error: unrecognized arguments: -x", stderr.getvalue())

        sys.argv = ['maintenance_json_generator.py',  '-v' , '999']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("error: argument -v/--version: invalid choice: '999'", stderr.getvalue())

        sys.argv = ['maintenance_json_generator.py', '--version', '43', '--slfo-pull-request', '9999']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("--slfo-pull-request is only supported for 51-* and 52-* versions", stderr.getvalue())

        sys.argv = ['maintenance_json_generator.py', '--version', '50-micro', '--slfo-pull-request', '9999']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("--slfo-pull-request is only supported for 51-* and 52-* versions", stderr.getvalue())

        sys.argv = ['maintenance_json_generator.py', '-v', '43', '-s', '9999']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("--slfo-pull-request is only supported for 51-* and 52-* versions", stderr.getvalue())

        sys.argv = ['maintenance_json_generator.py', '--version', '51-sles', '--slfo-pull-request', 'abc']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("invalid SLFO PullRequest id", stderr.getvalue())

        sys.argv = ['maintenance_json_generator.py', '--version', '51-sles', '--slfo-pull-request', '12/34']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("invalid SLFO PullRequest id", stderr.getvalue())

    def test_parse_cli_args_version_choices_match_nodes_by_version(self):
        for version in nodes_by_version.keys():
            sys.argv = ['maintenance_json_generator.py', '-v', version]
            args = parse_cli_args()
            self.assertEqual(args.version, version)

    def test_clean_mi_ids(self):
        # support 1234 4567 8901 format
        clean_ids: set[str] = clean_mi_ids(['123', '456', '789'])
        self.assertEqual(len(clean_ids), 3)
        self.assertSetEqual(clean_ids, {'123', '456', '789'})
        # support 1234,4567,8901 format
        clean_ids = clean_mi_ids(['123,456,789'])
        self.assertEqual(len(clean_ids), 3)
        self.assertSetEqual(clean_ids, {'123', '456', '789'})
        # support 1234, 4567, 8901 format
        clean_ids = clean_mi_ids(['123,', '456,', '789'])
        self.assertEqual(len(clean_ids), 3)
        self.assertSetEqual(clean_ids, {'123', '456', '789'})
        # handle duplicates
        clean_ids = clean_mi_ids(['123,', '456,', '123,', '456'])
        self.assertEqual(len(clean_ids), 2)
        self.assertSetEqual(clean_ids, {'123', '456'})

    @patch('json_generator.maintenance_json_generator.get_session')
    def test_create_url(self, mock_get_session):
        mock_http_call = mock_get_session.return_value.get
        mock_http_call.side_effect = mock_requests_get_success

        test_cases: list[tuple[str, str, bool]] = [
            ("1234", "/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/", True),
            ("1234", "/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_7_s390x/", False), # wrong suffix
            ("5678", "/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_s390x/", False), # wrong id
            ("5678", "/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_7_s390x/", False), # both wrong
        ]

        for test_id, test_suffix, valid in test_cases:
            expected_url: str = f"{IBS_MAINTENANCE_URL_PREFIX}{test_id}{test_suffix}" if valid else ""

            res: str = create_url(test_id, test_suffix)
            self.assertEqual(expected_url, res)
        
    @patch('json_generator.maintenance_json_generator.get_session')
    def test_create_url_cache(self, mock_get_session):
        create_url.cache_clear()
        mock_http_call = mock_get_session.return_value.get
        # the session is only asked by create_url when the result is not present in the LRU cache,
        # therefore we can check the number of times it gets called to verify if there was a cache hit
        mock_http_call.side_effect = mock_requests_get_success

        ids: set[str] = {"1234", "5678", "9012"}
        suffixes: set[str] = {"/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/", "/some/other/url/"}
        num_entries:int = len(ids)*len(suffixes)
        iterations: int = 3

        # the first iteration should result in all cache misses, the following ones should be all cache hits
        for i in range(iterations):
            for id in ids:
                for suffix in suffixes:
                    create_url(id, suffix)
            self.assertEqual(mock_http_call.call_count, num_entries, f"Iteration N°{i+1} of {iterations}")

    def test_setup_logging_silences_the_per_retry_warnings(self):
        urllib3_logger = logging.getLogger("urllib3.connectionpool")
        urllib3_logger.setLevel(logging.NOTSET)
        try:
            setup_logging()
            self.assertFalse(urllib3_logger.isEnabledFor(logging.WARNING))
            # only the per-retry chatter is dropped, a real error still shows
            self.assertTrue(urllib3_logger.isEnabledFor(logging.ERROR))
        finally:
            urllib3_logger.setLevel(logging.NOTSET)

    def test_get_session_hands_every_thread_its_own_session(self):
        sessions: list[requests.Session] = []
        lock = threading.Lock()

        def _collect():
            session = get_session()
            with lock:
                sessions.append(session)

        threads = [threading.Thread(target=_collect) for _ in range(4)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join()

        self.assertEqual(len(threads), len({id(session) for session in sessions}))
        # within a thread the session is reused, so the connection pool survives
        self.assertIs(get_session(), get_session())

    def test_session_retries_transient_statuses(self):
        for status in (408, 429, 500, 502, 503, 504, 599):
            with self.subTest(status=status):
                with _StatusSequenceServer([status, 200]) as server:
                    res = _session_without_backoff().get(server.url, timeout=(1, 5))
                    self.assertEqual(200, res.status_code)
                    self.assertEqual(2, server.requests)

    def test_session_gives_up_after_the_configured_attempts(self):
        with _StatusSequenceServer([503]) as server:
            # an exhausted retry raises, so the check is never mistaken for a 404
            self.assertRaises(requests.RequestException, _session_without_backoff().get, server.url, timeout=(1, 5))
            self.assertEqual(REQUEST_ATTEMPTS, server.requests)

    def test_session_retries_a_dropped_connection(self):
        with _ConnectionDroppingServer(drops=2) as server:
            res = _session_without_backoff().get(server.url, timeout=(1, 5))
            self.assertEqual(200, res.status_code)
            self.assertEqual(3, server.connections)

    def test_session_gives_up_on_a_connection_that_keeps_dropping(self):
        with _ConnectionDroppingServer(drops=REQUEST_ATTEMPTS) as server:
            self.assertRaises(requests.RequestException, _session_without_backoff().get, server.url, timeout=(1, 5))
            self.assertEqual(REQUEST_ATTEMPTS, server.connections)

    def test_session_does_not_retry_a_404(self):
        with _StatusSequenceServer([404]) as server:
            res = _session_without_backoff().get(server.url, timeout=(1, 5))
            self.assertEqual(404, res.status_code)
            self.assertEqual(1, server.requests)

    @patch('json_generator.maintenance_json_generator.get_session')
    def test_create_url_raises_on_any_status_other_than_success_or_404(self, mock_get_session):
        create_url.cache_clear()
        mock_http_call = mock_get_session.return_value.get
        # 304 is ok() as far as requests is concerned, but it says nothing about the repository
        for status in (304, 403, 500):
            with self.subTest(status=status):
                mock_http_call.return_value = MockResponse(status, status < 400)
                self.assertRaises(requests.HTTPError, create_url, str(status), "/some_repo/")

    @patch('json_generator.maintenance_json_generator.requests.get')
    def test_probe_url_only_trusts_a_2xx_or_a_404(self, mock_http_call):
        probe_url.cache_clear()
        for status, expected in ((200, True), (404, False), (408, None), (500, None), (599, None)):
            with self.subTest(status=status):
                mock_http_call.return_value = MockResponse(status, status < 400)
                self.assertEqual(expected, probe_url(f"http://ibs.example/{status}/"))

    @patch('json_generator.maintenance_json_generator.requests.get')
    def test_probe_url_retries_a_transient_status_but_not_a_definitive_one(self, mock_http_call):
        # a status IBS answers the same way every time is not worth a second request
        for status, expected_requests in ((503, REQUEST_ATTEMPTS), (429, REQUEST_ATTEMPTS), (403, 1), (400, 1)):
            with self.subTest(status=status):
                probe_url.cache_clear()
                mock_http_call.reset_mock()
                mock_http_call.return_value = MockResponse(status, False)
                self.assertIsNone(probe_url(f"http://ibs.example/{status}/"))
                self.assertEqual(expected_requests, mock_http_call.call_count)

    @patch('logging.warning')
    @patch('json_generator.maintenance_json_generator.probe_url')
    def test_warn_on_unresolved_uyuni_tools_repos_reports_an_unanswered_probe(self, mock_probe, mock_logger):
        url = 'http://ibs.example/ToTest/server_uyuni_tools/'
        custom_repositories = {'server': {'server_uyuni_tools': url}}

        mock_probe.return_value = None
        warn_on_unresolved_uyuni_tools_repos(custom_repositories)
        mock_logger.assert_called_with(f"server: server_uyuni_tools could not be checked on IBS: {url}")

        mock_probe.return_value = False
        warn_on_unresolved_uyuni_tools_repos(custom_repositories)
        mock_logger.assert_called_with(f"server: server_uyuni_tools does not exist on IBS: {url}")

        mock_logger.reset_mock()
        mock_probe.return_value = True
        warn_on_unresolved_uyuni_tools_repos(custom_repositories)
        mock_logger.assert_not_called()

    @patch('json_generator.maintenance_json_generator.requests.get')
    def test_url_exists_stops_the_run_on_an_unanswered_probe(self, mock_http_call):
        probe_url.cache_clear()
        # a transient answer must not make the path look absent and pick the other project family
        mock_http_call.return_value = MockResponse(503, False)
        self.assertRaises(SystemExit, url_exists, "http://ibs.example/unanswered/")

    @patch('json_generator.maintenance_json_generator.get_session')
    def test_create_url_does_not_cache_an_unanswered_check(self, mock_get_session):
        create_url.cache_clear()
        mock_http_call = mock_get_session.return_value.get
        mock_http_call.side_effect = [requests.ConnectionError("boom"), MockResponse(200, True)]

        self.assertRaises(requests.ConnectionError, create_url, "1234", "/some_repo/")
        self.assertEqual(f"{IBS_MAINTENANCE_URL_PREFIX}1234/some_repo/", create_url("1234", "/some_repo/"))

    @patch('logging.warning')
    def test_validate_and_store_results(self, mock_logger):
        test_output_file: str = 'test_custom_repositories.json'
        test_mi_ids: set[str] = {"123", "456", "789"}
        # empty custom_repositories
        self.assertRaises(SystemExit, validate_and_store_results, test_mi_ids, {}, test_output_file)

        test_custom_repos: dict[str, dict[str, str]] = {
            'server': {'123': 'some repo', '789': 'some repo'},
            'proxy': {'123': 'some_repo', 'proxy_50': 'some repo'},
            'some minion': {'789': 'some repo'}
        }
        # missing MI ID 456
        validate_and_store_results(test_mi_ids, test_custom_repos, test_output_file)
        mock_logger.assert_called_with(
            "MI IDs ['456'] have no repository in the final JSON, "
            "perhaps they are not for the version you are running the script for."
        )

        test_custom_repos['some minion']['456'] = "some repo"
        validate_and_store_results(test_mi_ids, test_custom_repos, test_output_file)
        self.assertTrue(path.isfile(test_output_file))
        
        with open(test_output_file) as json_output:
            output_json: dict[str, dict[str, str]] = json.load(json_output)
            self.assertDictEqual(test_custom_repos, output_json)

        # cleanup
        remove(test_output_file)

    @patch('logging.error')
    def test_abort_on_unanswered_checks(self, mock_logger):
        test_output_file: str = 'test_unanswered_repositories.json'
        unanswered: list[tuple[str, str]] = [("123/some_repo/", "connection refused")]

        self.assertRaises(SystemExit, abort_on_unanswered_checks, unanswered, test_output_file)
        mock_logger.assert_called_with("No answer for 123/some_repo/: connection refused")
        # an incomplete result must not be written
        self.assertFalse(path.isfile(test_output_file))

    def test_abort_on_unanswered_checks_lets_a_complete_run_through(self):
        abort_on_unanswered_checks([])

    def test_get_version_nodes(self):
        # 4.3
        self.assertDictEqual(nodes_by_version['43'], get_version_nodes('43'))
        # 5.0
        self.assertDictEqual(nodes_by_version['50-micro'], get_version_nodes('50-micro'))
        # invalid
        self.assertRaises(ValueError, get_version_nodes, '99')

    def test_init_custom_repositories(self):
        self.assertEqual({}, init_custom_repositories(None))
        self.assertEqual({}, init_custom_repositories({}))
        salt_static = v43_static_slmicro_salt_repositories
        custom_repos: dict[str, dict[str, str]] = init_custom_repositories(salt_static)
        self.assertIn('slmicro60_minion', custom_repos)
        self.assertIn('slmicro61_minion', custom_repos)
        self.assertEqual(
            set(custom_repos['slmicro60_minion'].keys()),
            {'slmicro60_salt'},
        )
        self.assertEqual(
            set(custom_repos['slmicro61_minion'].keys()),
            {'slmicro61_salt'},
        )

    def test_apply_slfo_pullrequest_client_tools(self):
        custom_repos: dict[str, dict[str, str]] = {}

        apply_slfo_pullrequest_client_tools(custom_repos, '12345')

        self.assertDictEqual(
            {
                'sles160_minion': {
                    'slfo_pr_12345_sles160_x86_64': 'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools:/PullRequest:/12345:/SLES/product/repo/Multi-Linux-ManagerTools-SLE-16-x86_64/'
                },
                'slmicro62_minion': {
                    'slfo_pr_12345_slmicro62_x86_64': 'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools:/PullRequest:/12345:/SLES/product/repo/Multi-Linux-ManagerTools-SLE-16-x86_64/'
                },
                'opensuse160arm_minion': {
                    'slfo_pr_12345_opensuse160arm_aarch64': 'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools:/PullRequest:/12345:/SLES/product/repo/Multi-Linux-ManagerTools-SLE-16-aarch64/'
                },
            },
            custom_repos,
        )

    def test_slfo_pullrequest_client_tool_url_embeds_architecture(self):
        x86_url = slfo_pullrequest_client_tool_url('362', arch='x86_64')
        aarch64_url = slfo_pullrequest_client_tool_url('362', arch='aarch64')

        self.assertIn('Multi-Linux-ManagerTools-SLE-16-x86_64/', x86_url)
        self.assertIn('Multi-Linux-ManagerTools-SLE-16-aarch64/', aarch64_url)
        self.assertNotIn('aarch64', x86_url)
        self.assertNotIn('x86_64', aarch64_url)

    def test_sle16_minions_use_static_slfo_client_tools(self):
        x86_64_url = 'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools:/SLES-16:/ToTest/product/repo/Multi-Linux-ManagerTools-SLE-16-x86_64/'
        aarch64_url = 'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools:/SLES-16:/ToTest/product/repo/Multi-Linux-ManagerTools-SLE-16-aarch64/'
        for get_static_and_client_tools in (
            get_v51_static_and_client_tools,
            get_v52_static_and_client_tools,
        ):
            static, dynamic = get_static_and_client_tools('sles')
            self.assertEqual(static['sles160_minion']['sles16_client_tools'], x86_64_url)
            self.assertEqual(static['slmicro62_minion']['sles16_client_tools'], x86_64_url)
            self.assertEqual(static['opensuse160arm_minion']['sles16_client_tools'], aarch64_url)
            self.assertNotIn('opensuse160arm_minion', dynamic)

    def test_slmicro6_minions_keep_their_static_salt_repos(self):
        salt_urls = {
            'slmicro60_minion': (
                'slmicro60_salt',
                'http://download.suse.de/ibs/SUSE:/ALP:/Source:/Standard:/1.0:/Staging:/Z/images/repo/SL-Micro-6.0-x86_64/',
            ),
            'slmicro61_minion': (
                'slmicro61_salt',
                'http://download.suse.de/ibs/SUSE:/SLFO:/1.1:/Staging:/Z/images/repo/SL-Micro-6.1-x86_64/',
            ),
        }
        for get_static_and_client_tools in (
            get_v51_static_and_client_tools,
            get_v52_static_and_client_tools,
        ):
            for variant in ('sles', 'micro'):
                static, _dynamic = get_static_and_client_tools(variant)
                for node, (repo_name, url) in salt_urls.items():
                    self.assertEqual(static[node][repo_name], url)
                    self.assertIn('slmicro6_client_tools', static[node])

    def test_raspios13_uses_debian13_aarch64_client_tools(self):
        for get_static_and_client_tools in (
            get_v51_static_and_client_tools,
            get_v52_static_and_client_tools,
        ):
            _static, dynamic = get_static_and_client_tools('sles')
            self.assertEqual(
                dynamic['raspios13_minion'],
                ['/SUSE_Updates_MultiLinuxManagerTools_Debian-13_aarch64/'],
            )

        _static, dynamic = get_v53_static_and_client_tools('sles', beta=True)
        self.assertEqual(
            dynamic['raspios13_minion'],
            ['/SUSE_Updates_MultiLinuxManagerTools-Beta_Debian-13_aarch64/'],
        )

    @patch('logging.error')
    @patch('json_generator.maintenance_json_generator.create_url')
    @patch('json_generator.maintenance_json_generator.validate_and_store_results')
    def test_find_valid_repos_aborts_on_unanswered_checks(self, mock_validate, mock_create_url, mock_logger):
        mock_create_url.side_effect = requests.ConnectionError("boom")

        self.assertRaises(SystemExit, find_valid_repos, {'1234'}, '52-sles')

        # the run stops before anything can be written
        mock_validate.assert_not_called()
        reported = [call.args[0] for call in mock_logger.call_args_list]
        self.assertTrue(reported)
        self.assertTrue(all(message.startswith("No answer for 1234") for message in reported))
        self.assertTrue(all(message.endswith("boom") for message in reported))

    @patch('json_generator.maintenance_json_generator.probe_url', return_value=True)
    @patch('json_generator.maintenance_json_generator.url_exists', side_effect=_only_client_tools_exist)
    @patch('json_generator.maintenance_json_generator.validate_and_store_results')
    def test_slfo_pullrequest_injects_opensuse160arm_in_find_valid_repos(self, _mock_validate, _mock_url_exists, _mock_probe_url):
        captured: dict[str, dict[str, dict[str, str]]] = {}

        def _capture(_ids, custom_repositories, *_args, **_kwargs):
            captured['repos'] = custom_repositories

        _mock_validate.side_effect = _capture

        find_valid_repos(set(), '52-sles', slfo_pull_request_ids=['12345'])

        repos = captured['repos']
        self.assertIn('opensuse160arm_minion', repos)
        self.assertEqual(
            repos['opensuse160arm_minion'].get('slfo_pr_12345_opensuse160arm_aarch64'),
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools:/PullRequest:/12345:/SLES/product/repo/Multi-Linux-ManagerTools-SLE-16-aarch64/',
        )
        self.assertIn('sles160_minion', repos)
        self.assertIn('slmicro62_minion', repos)
        # the PullRequest client tools supersede the :ToTest ones on every SLE-16 minion
        for node in ('sles160_minion', 'slmicro62_minion', 'opensuse160arm_minion'):
            self.assertNotIn('sles16_client_tools', repos[node])

    @patch('json_generator.maintenance_json_generator.url_exists')
    def test_classify_slfo_pull_requests_sorts_ids_by_project(self, mock_url_exists):
        # 370 only exists in MultiLinuxManagerTools, 65 only in Multi-Linux-Manager Packages
        def _exists(url: str) -> bool:
            if CLIENT_TOOLS_PR_PROJECT in url:
                return '/370:/' in url
            return '/65:/' in url

        mock_url_exists.side_effect = _exists

        self.assertDictEqual(
            {'client_tools': ['370'], 'mlm_packages': ['65']},
            classify_slfo_pull_requests(['370', '65'], '52-micro'),
        )

    @patch('json_generator.maintenance_json_generator.url_exists', return_value=False)
    def test_classify_slfo_pull_requests_rejects_unknown_id(self, _mock_url_exists):
        with self.assertRaises(SystemExit) as cm:
            classify_slfo_pull_requests(['9999'], '52-micro')
        self.assertIn('9999 was not found on IBS', str(cm.exception))

    @patch('json_generator.maintenance_json_generator.url_exists', return_value=True)
    def test_classify_slfo_pull_requests_rejects_ambiguous_id(self, _mock_url_exists):
        with self.assertRaises(SystemExit) as cm:
            classify_slfo_pull_requests(['42'], '52-micro')
        self.assertIn('exists in more than one project', str(cm.exception))

    @patch('json_generator.maintenance_json_generator.url_exists', side_effect=_only_mlm_packages_exist)
    def test_mlm_packages_pullrequest_replaces_totest_server_and_proxy(self, _mock_url_exists):
        custom_repos = init_custom_repositories(get_version_nodes('52-micro')['static'])
        self.assertIn('server_uyuni_tools', custom_repos['server'])

        apply_slfo_pull_requests(custom_repos, ['65'], '52-micro')

        self.assertNotIn('server_uyuni_tools', custom_repos['server'])
        self.assertEqual(
            custom_repos['server']['slfo_pr_65_server_uyuni_tools'],
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.2:/Packages:/PullRequest:/65:/SL-Micro/product/repo/Multi-Linux-Manager-Server-5.2-x86_64/',
        )
        self.assertNotIn('proxy_uyuni_tools', custom_repos['proxy'])
        self.assertNotIn('retail_uyuni_tools', custom_repos['proxy'])
        self.assertEqual(
            custom_repos['proxy']['slfo_pr_65_proxy_uyuni_tools'],
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.2:/Packages:/PullRequest:/65:/SL-Micro/product/repo/Multi-Linux-Manager-Proxy-5.2-x86_64/',
        )
        self.assertEqual(
            custom_repos['proxy']['slfo_pr_65_retail_uyuni_tools'],
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.2:/Packages:/PullRequest:/65:/SL-Micro/product/repo/Multi-Linux-Manager-Retail-Branch-Server-5.2-x86_64/',
        )
        # the SL Micro 6 client tools of the proxy are a different project, untouched
        self.assertIn('slmicro6_client_tools', custom_repos['proxy'])

    @patch('json_generator.maintenance_json_generator.url_exists', side_effect=_only_mlm_packages_exist)
    def test_mlm_packages_pullrequest_skipped_on_sles_variant(self, _mock_url_exists):
        custom_repos = init_custom_repositories(get_version_nodes('52-sles')['static'])

        apply_slfo_pull_requests(custom_repos, ['65'], '52-sles')

        self.assertNotIn('slfo_pr_65_server_uyuni_tools', custom_repos.get('server', {}))

    def test_mlm_product_version(self):
        self.assertEqual(mlm_product_version('52-micro'), '5.2')
        self.assertEqual(mlm_product_version('51-sles'), '5.1')
        self.assertEqual(mlm_product_version('53-micro-beta'), '5.3')

    def test_slfo_pull_request_requires_at_least_one_id(self):
        sys.argv = ['maintenance_json_generator.py', '--version', '52-micro', '--slfo-pull-request']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("expected at least one argument", stderr.getvalue())

    def test_slfo_pull_request_rejected_for_unsupported_versions(self):
        # --slfo-pull-request is only supported for 51-* and 52-* versions
        # 5.3 versions (beta or not) are rejected due to version range check
        sys.argv = ['maintenance_json_generator.py', '--version', '53-sles-beta', '--slfo-pull-request', '9999']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("--slfo-pull-request is only supported for 51-* and 52-* versions", stderr.getvalue())

        sys.argv = ['maintenance_json_generator.py', '--version', '53-micro-beta', '--slfo-pull-request', '9999']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("--slfo-pull-request is only supported for 51-* and 52-* versions", stderr.getvalue())

    @patch('json_generator.maintenance_json_generator.probe_url', return_value=True)
    @patch('json_generator.maintenance_json_generator.validate_and_store_results')
    def test_beta_version_injects_totest_static_urls(self, _mock_validate, _mock_probe_url):
        # Beta versions must auto-populate sles160_minion and slmicro62_minion
        # from the static :ToTest map (no --slfo-pull-request required).
        # Updated to test 5.3 beta (5.2 is now stable)
        captured: dict[str, dict[str, dict[str, str]]] = {}

        def _capture(_ids, custom_repositories, *_args, **_kwargs):
            captured['repos'] = custom_repositories

        _mock_validate.side_effect = _capture

        find_valid_repos(set(), '53-sles-beta')

        repos = captured['repos']
        self.assertIn('sles160_minion', repos)
        self.assertIn('slmicro62_minion', repos)
        sles16_url = (
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools-Beta:/SLES-16:'
            '/ToTest/product/repo/Multi-Linux-ManagerTools-Beta-SLE-16-x86_64/'
        )
        self.assertEqual(repos['sles160_minion'].get('sles16_client_tools'), sles16_url)
        self.assertEqual(repos['slmicro62_minion'].get('sles16_client_tools'), sles16_url)
        self.assertEqual(
            repos['server'].get('mlm53_sles_beta_totest_images_sp7'),
            'http://download.suse.de/ibs/SUSE:/SLE-15-SP7:/Update:/Products:/MultiLinuxManager53:/ToTest/'
            'images-SP7/repo/SUSE-Multi-Linux-Manager-Server-SLE-5.3-POOL-x86_64-Media1/',
        )
        self.assertEqual(
            repos['proxy'].get('mlm53_sles_beta_totest_images_sp7_proxy'),
            'http://download.suse.de/ibs/SUSE:/SLE-15-SP7:/Update:/Products:/MultiLinuxManager53:/ToTest/'
            'images-SP7/repo/SUSE-Multi-Linux-Manager-Proxy-SLE-5.3-POOL-x86_64-Media1/',
        )

        find_valid_repos(set(), '53-micro-beta')
        repos_micro = captured['repos']
        self.assertEqual(
            repos_micro['server'].get('server_uyuni_tools'),
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.3:/ToTest/product/repo/'
            'Multi-Linux-Manager-Server-5.3-x86_64/',
        )
        self.assertEqual(
            repos_micro['proxy'].get('proxy_uyuni_tools'),
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.3:/ToTest/product/repo/'
            'Multi-Linux-Manager-Proxy-5.3-x86_64/',
        )

    def test_v52_sles_stable_includes_totest_static_repos(self):
        # Test that 5.2 stable (non-beta) includes the new static ToTest image repos
        static, _dynamic = get_v52_static_and_client_tools('sles')

        # Server should have the ToTest image repo
        self.assertIn('server', static)
        self.assertIn('mlm52_sles_totest_images_sp7', static['server'])
        server_url = static['server']['mlm52_sles_totest_images_sp7']
        self.assertTrue(server_url.startswith('http://download.suse.de/ibs/SUSE:'))
        self.assertIn('SLE-15-SP7:/Update:/Products:/MultiLinuxManager52:/ToTest/', server_url)
        self.assertIn('SUSE-Multi-Linux-Manager-Server-SLE-5.2-POOL-x86_64-Media1/', server_url)

        # Proxy should have the ToTest image repo
        self.assertIn('proxy', static)
        self.assertIn('mlm52_sles_totest_images_sp7_proxy', static['proxy'])
        proxy_url = static['proxy']['mlm52_sles_totest_images_sp7_proxy']
        self.assertTrue(proxy_url.startswith('http://download.suse.de/ibs/SUSE:'))
        self.assertIn('SLE-15-SP7:/Update:/Products:/MultiLinuxManager52:/ToTest/', proxy_url)
        self.assertIn('SUSE-Multi-Linux-Manager-Proxy-SLE-5.2-POOL-x86_64-Media1/', proxy_url)

    def test_v52_micro_stable_includes_totest_static_repos(self):
        # Test that 5.2 micro stable includes the SLFO ToTest product repos
        static, _dynamic = get_v52_static_and_client_tools('micro')

        # Server should have ToTest repo
        self.assertIn('server', static)
        self.assertIn('server_uyuni_tools', static['server'])
        server_url = static['server']['server_uyuni_tools']
        self.assertEqual(
            server_url,
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.2:/ToTest/product/repo/'
            'Multi-Linux-Manager-Server-5.2-x86_64/'
        )

        # Proxy should have ToTest repos including slmicro6_client_tools
        self.assertIn('proxy', static)
        self.assertIn('proxy_uyuni_tools', static['proxy'])
        self.assertIn('retail_uyuni_tools', static['proxy'])
        self.assertIn('slmicro6_client_tools', static['proxy'])

        proxy_url = static['proxy']['proxy_uyuni_tools']
        self.assertEqual(
            proxy_url,
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.2:/ToTest/product/repo/'
            'Multi-Linux-Manager-Proxy-5.2-x86_64/'
        )

        retail_url = static['proxy']['retail_uyuni_tools']
        self.assertEqual(
            retail_url,
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.2:/ToTest/product/repo/'
            'Multi-Linux-Manager-Retail-Branch-Server-5.2-x86_64/'
        )

        slmicro6_url = static['proxy']['slmicro6_client_tools']
        self.assertEqual(
            slmicro6_url,
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools:/SL-Micro-6:/ToTest/product/repo/'
            'Multi-Linux-ManagerTools-SL-Micro-6-x86_64/'
        )

    @patch('json_generator.maintenance_json_generator.probe_url', return_value=True)
    @patch('json_generator.maintenance_json_generator.validate_and_store_results')
    def test_v52_sles_stable_totest_repos_in_final_output(self, _mock_validate, _mock_probe_url):
        # Verify that the static ToTest repos appear in the final custom_repositories output
        captured: dict[str, dict[str, dict[str, str]]] = {}

        def _capture(_ids, custom_repositories, *_args, **_kwargs):
            captured['repos'] = custom_repositories

        _mock_validate.side_effect = _capture

        # Generate for 52-sles with no MI IDs to verify static repos appear
        find_valid_repos(set(), '52-sles')

        repos = captured['repos']

        # Verify the static ToTest repos are present in final output
        self.assertEqual(
            repos['server'].get('mlm52_sles_totest_images_sp7'),
            'http://download.suse.de/ibs/SUSE:/SLE-15-SP7:/Update:/Products:/MultiLinuxManager52:/ToTest/'
            'images-SP7/repo/SUSE-Multi-Linux-Manager-Server-SLE-5.2-POOL-x86_64-Media1/',
        )
        self.assertEqual(
            repos['proxy'].get('mlm52_sles_totest_images_sp7_proxy'),
            'http://download.suse.de/ibs/SUSE:/SLE-15-SP7:/Update:/Products:/MultiLinuxManager52:/ToTest/'
            'images-SP7/repo/SUSE-Multi-Linux-Manager-Proxy-SLE-5.2-POOL-x86_64-Media1/',
        )

    def test_v51_v52_v53_dynamic_repos_are_sorted_lists(self):
        # 5.2 no longer has beta parameter (it's now stable)
        # Test 5.1, 5.2 stable, and 5.3 beta
        test_cases = [
            get_v51_static_and_client_tools('sles')[1],
            get_v52_static_and_client_tools('sles')[1],
            get_v53_static_and_client_tools('sles', beta=True)[1],
        ]

        for dynamic_repos in test_cases:
            self.assertIsInstance(dynamic_repos['server'], list)
            self.assertIsInstance(dynamic_repos['proxy'], list)
            self.assertEqual(dynamic_repos['server'], sorted(dynamic_repos['server']))
            self.assertEqual(dynamic_repos['proxy'], sorted(dynamic_repos['proxy']))

    def test_update_custom_repositories(self):
        custom_repos: dict[str, dict[str, str]] = {}
        # node not present
        update_custom_repositories(custom_repos, 'test_node_1', '1234', '1234_url')
        self.assertDictEqual({
            'test_node_1': {
                '1234': '1234_url'
            }
        }, custom_repos)
        # node already present - new MI ID
        update_custom_repositories(custom_repos, 'test_node_1', '5678', '5678_url')
        self.assertDictEqual({
            'test_node_1': {
                '1234': '1234_url',
                '5678': '5678_url'
            }
        }, custom_repos)
        # node already present - MI ID already exists
        update_custom_repositories(custom_repos, 'test_node_1', '1234', '2nd_1234_url')
        self.assertDictEqual({
            'test_node_1': {
                '1234': '1234_url',
                '1234_1': '2nd_1234_url',
                '5678': '5678_url'
            }
        }, custom_repos)
        # new node but MI ID was already used
        update_custom_repositories(custom_repos, 'test_node_2', '1234', '1234_url')
        self.assertDictEqual({
            'test_node_1': {
                '1234': '1234_url',
                '1234_1': '2nd_1234_url',
                '5678': '5678_url'
            },
            'test_node_2': {
                '1234': '1234_url',
            },
        }, custom_repos)
        # same node and same MI ID (2nd time)
        update_custom_repositories(custom_repos, 'test_node_1', '1234', '3rd_1234_url')
        self.assertDictEqual({
            'test_node_1': {
                '1234': '1234_url',
                '1234_1': '2nd_1234_url',
                '1234_2': '3rd_1234_url',
                '5678': '5678_url'
            },
            'test_node_2': {
                '1234': '1234_url',
            },
        }, custom_repos)


    def test_read_mi_ids_from_file(self):
        test_file_path = TESTDATA_DIR / 'mi_ids_file.txt'

        file_ids: list[str] = read_mi_ids_from_file(test_file_path)
        self.assertEqual(file_ids, ['11111', '22222', '33333'])

        self.assertRaises(OSError, read_mi_ids_from_file, 'file_not_found.txt')

    def test_merge_mi_ids(self):
        test_file_path = TESTDATA_DIR / 'mi_ids_file.txt'
        test_file_path_str = str(test_file_path)
        # no ids at all
        sys.argv = ['maintenance_json_generator.py', '-v', '50-micro']
        args = parse_cli_args()
        ids: set[str] = merge_mi_ids(args)
        self.assertEqual(ids, set())
        # no mi ids file
        sys.argv = ['maintenance_json_generator.py', '-v', '50-micro', '-i', '1234', '5678', '-e']
        args = parse_cli_args()
        ids: set[str] = merge_mi_ids(args)
        self.assertEqual(ids, {'1234', '5678'})
        # only mi ids file
        sys.argv = ['maintenance_json_generator.py', '-v', '50-micro', '-f', test_file_path_str, '-e']
        args = parse_cli_args()
        ids: set[str] = merge_mi_ids(args)
        self.assertEqual(ids, {'11111', '22222', '33333'})
        # ids both from flag and file
        sys.argv = ['maintenance_json_generator.py', '-v', '50-micro', '-f', test_file_path_str, '-i', '1234', '5678', '-e']
        args = parse_cli_args()
        ids: set[str] = merge_mi_ids(args)
        self.assertEqual(ids, {'1234', '5678', '11111', '22222', '33333'})
        # duplicated IDs from flag and file should be removed
        sys.argv = ['maintenance_json_generator.py', '-v', '50-micro', '-f', test_file_path_str, '-i', '11111', '1234', '33333', '5678', '-e']
        args = parse_cli_args()
        ids: set[str] = merge_mi_ids(args)
        self.assertEqual(ids, {'1234', '5678', '11111', '22222', '33333'})
        # check alternate -i flag values format
        sys.argv = ['maintenance_json_generator.py', '-v', '50-micro', '-f', test_file_path_str, '-i', '11111,1234,33333,5678', '-e']
        args = parse_cli_args()
        ids: set[str] = merge_mi_ids(args)
        self.assertEqual(ids, {'1234', '5678', '11111', '22222', '33333'})

if __name__ == '__main__':
    unittest.main()
