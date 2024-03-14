from argparse import Namespace
import sys
import unittest
from unittest.mock import patch

from json_generator.maintenance_json_generator import create_url, IBS_MAINTENANCE_URL_PREFIX, parse_cli_args
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

if __name__ == '__main__':
    unittest.main()
