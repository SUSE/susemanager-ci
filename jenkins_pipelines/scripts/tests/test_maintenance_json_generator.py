from argparse import Namespace
import json
from os import path, remove
import sys
import unittest
from unittest.mock import patch

from json_generator.maintenance_json_generator import clean_mi_ids, create_url, IBS_MAINTENANCE_URL_PREFIX, parse_cli_args, validate_and_store_results
from tests.mock_response import mock_requests_get_success


class MaintenanceJsonGeneratorTestCase(unittest.TestCase):

    def test_parse_cli_args_default_values(self):
        sys.argv= ['maintenance_json_generator.py']
        args = parse_cli_args()
        self.assertEqual(args.version, "43")
        self.assertIsNone(args.mi_ids)
        self.assertFalse(args.embargo_check)

    def test_parse_cli_args_success(self):
        # shorthand flags
        sys.argv= ['maintenance_json_generator.py', '-v', '50', '-i', '1234', '5678', '-e']
        args: Namespace = parse_cli_args()
        self.assertEqual(args.version, "50")
        self.assertListEqual(args.mi_ids, ['1234', '5678'])
        self.assertTrue(args.embargo_check)
        # shorthand flags - mi_ids variant 1
        sys.argv= ['maintenance_json_generator.py', '-v', '50', '-i', '1234,5678', '-e']
        args: Namespace = parse_cli_args()
        self.assertEqual(args.version, "50")
        self.assertListEqual(args.mi_ids, ['1234,5678'])
        self.assertTrue(args.embargo_check)
        # shorthand flags - mi_ids variant 2
        sys.argv= ['maintenance_json_generator.py', '-v', '50', '-i', '1234,', '5678', '-e']
        args: Namespace = parse_cli_args()
        self.assertEqual(args.version, "50")
        self.assertListEqual(args.mi_ids, ['1234,' , '5678'])
        self.assertTrue(args.embargo_check)
        # long flags
        sys.argv= ['maintenance_json_generator.py', '--version', '50', '--mi_ids', '1234', '5678', '--no_embargo']
        args: Namespace = parse_cli_args()
        self.assertEqual(args.version, "50")
        self.assertListEqual(args.mi_ids, ['1234', '5678'])
        self.assertTrue(args.embargo_check)
    
    def test_parse_cli_args_failure(self):
        sys.argv= ['maintenance_json_generator.py',  '-x']
        with self.assertRaises(SystemExit) as cm:
            parse_cli_args()
            self.assertEqual(cm.exception.code, 2)
            self.assertIn("error: unrecognized arguments: -x", cm.msg)

        sys.argv= ['maintenance_json_generator.py',  '-v' , '999']
        with self.assertRaises(SystemExit) as cm:
            parse_cli_args()
            self.assertEqual(cm.exception.code, 2)
            self.assertIn("error: argument -v/--version: invalid choice: '999'", cm.msg)

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

    def test_validate_and_store_results(self):
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
        self.assertRaises(SystemExit, validate_and_store_results, test_mi_ids, test_custom_repos, test_output_file) 
        
        test_custom_repos['some minion']['456'] = "some repo"
        validate_and_store_results(test_mi_ids, test_custom_repos, test_output_file)
        self.assertTrue(path.isfile(test_output_file))
        
        with open(test_output_file) as json_output:
            output_json: dict[str, dict[str, str]] = json.load(json_output)
            self.assertDictEqual(test_custom_repos, output_json)
        
        # cleanup
        remove(test_output_file)


if __name__ == '__main__':
    unittest.main()
