from argparse import Namespace
from contextlib import redirect_stderr
import io
import json
from os import path, remove
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

from json_generator.maintenance_json_generator import *
from repository_versions.v43_nodes import v43_static_slmicro_salt_repositories
from repository_versions.v51_nodes import get_v51_static_and_client_tools
from repository_versions.v52_nodes import get_v52_static_and_client_tools
from tests.mock_response import mock_requests_get_success

TESTDATA_DIR = Path(__file__).resolve().parent / 'testdata'

class MaintenanceJsonGeneratorTestCase(unittest.TestCase):

    def test_parse_cli_args_default_values(self):
        sys.argv = ['maintenance_json_generator.py']
        args = parse_cli_args()
        self.assertEqual(args.version, "51-sles")
        self.assertIsNone(args.mi_ids)
        self.assertFalse(args.embargo_check)
        self.assertIsNone(args.slfo_pull_request)

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
        self.assertEqual(args.slfo_pull_request, '9999')

    def test_parse_cli_args_failure(self):
        sys.argv = ['maintenance_json_generator.py',  '-x']
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

    @patch('requests.get')
    def test_create_url(self, mock_http_call):
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
        
    @patch('requests.get')
    def test_create_url_cache(self, mock_http_call):
        create_url.cache_clear()
        # requests.get is only called by create_url when the results is not present in the LRU cache,
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

    @patch('logging.error')
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
        mock_logger.assert_called_with("MI IDs #{'456'} do not exist in custom_repositories dictionary.")
        
        test_custom_repos['some minion']['456'] = "some repo"
        validate_and_store_results(test_mi_ids, test_custom_repos, test_output_file)
        self.assertTrue(path.isfile(test_output_file))
        
        with open(test_output_file) as json_output:
            output_json: dict[str, dict[str, str]] = json.load(json_output)
            self.assertDictEqual(test_custom_repos, output_json)
        
        # cleanup
        remove(test_output_file)

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
            {'slmicro60_salt', 'slmicro6_salt_bundle'},
        )
        self.assertEqual(
            set(custom_repos['slmicro61_minion'].keys()),
            {'slmicro61_salt', 'slmicro6_salt_bundle'},
        )

    def test_apply_slfo_pullrequest_client_tools(self):
        custom_repos: dict[str, dict[str, str]] = {}

        apply_slfo_pullrequest_client_tools(custom_repos, '12345')

        self.assertDictEqual(
            {
                'sles160_minion': {
                    'slfo_pr_12345': 'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools:/PullRequest:/12345:/SLES/product/repo/Multi-Linux-ManagerTools-SLE-16-x86_64/'
                },
                'slmicro62_minion': {
                    'slfo_pr_12345': 'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools:/PullRequest:/12345:/SLES/product/repo/Multi-Linux-ManagerTools-SLE-16-x86_64/'
                },
            },
            custom_repos,
        )

    def test_slfo_pull_request_rejected_for_beta(self):
        sys.argv = ['maintenance_json_generator.py', '--version', '52-sles-beta', '--slfo-pull-request', '9999']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("--slfo-pull-request is not supported for beta versions", stderr.getvalue())

        sys.argv = ['maintenance_json_generator.py', '--version', '52-micro-beta', '--slfo-pull-request', '9999']
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as cm:
                parse_cli_args()
        self.assertEqual(cm.exception.code, 2)
        self.assertIn("--slfo-pull-request is not supported for beta versions", stderr.getvalue())

    @patch('json_generator.maintenance_json_generator.validate_and_store_results')
    def test_beta_version_injects_totest_static_urls(self, _mock_validate):
        # Beta versions must auto-populate sles160_minion and slmicro62_minion
        # from the static :ToTest map (no --slfo-pull-request required).
        captured: dict[str, dict[str, dict[str, str]]] = {}

        def _capture(_ids, custom_repositories, *_args, **_kwargs):
            captured['repos'] = custom_repositories

        _mock_validate.side_effect = _capture

        find_valid_repos(set(), '52-sles-beta')

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
            repos['server'].get('mlm52_sles_beta_totest_images_sp7'),
            'http://download.suse.de/ibs/SUSE:/SLE-15-SP7:/Update:/Products:/MultiLinuxManager52:/ToTest/'
            'images-SP7/repo/SUSE-Multi-Linux-Manager-Server-SLE-5.2-POOL-x86_64-Media1/',
        )
        self.assertEqual(
            repos['proxy'].get('mlm52_sles_beta_totest_images_sp7_proxy'),
            'http://download.suse.de/ibs/SUSE:/SLE-15-SP7:/Update:/Products:/MultiLinuxManager52:/ToTest/'
            'images-SP7/repo/SUSE-Multi-Linux-Manager-Proxy-SLE-5.2-POOL-x86_64-Media1/',
        )

        find_valid_repos(set(), '52-micro-beta')
        repos_micro = captured['repos']
        self.assertEqual(
            repos_micro['server'].get('server_uyuni_tools'),
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.2:/ToTest/product/repo/'
            'Multi-Linux-Manager-Server-5.2-x86_64/',
        )
        self.assertEqual(
            repos_micro['proxy'].get('proxy_uyuni_tools'),
            'http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.2:/ToTest/product/repo/'
            'Multi-Linux-Manager-Proxy-5.2-x86_64/',
        )

    def test_v51_v52_dynamic_repos_are_sorted_lists(self):
        test_cases = [
            get_v51_static_and_client_tools('sles')[1],
            get_v52_static_and_client_tools('sles', beta=False)[1],
            get_v52_static_and_client_tools('sles', beta=True)[1],
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
