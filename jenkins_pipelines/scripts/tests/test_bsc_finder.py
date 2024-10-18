import json
from os import path, remove
import sys
import unittest

from bsc_list_generator.bsc_finder import parse_cli_args, get_suma_product_name, get_suma_bugzilla_products, bugs_to_links_list, store_results
from bsc_list_generator.bugzilla_client import BugzillaClient

class BscFinderTestCase(unittest.TestCase):

    def setUp(self):
        self.bugzilla_client: BugzillaClient = BugzillaClient("test_key")
        self.mock_bugs: dict[str, list[dict]] = {
            "Test Product": [
                {
                    "classification": "Test",
                    "component": "Test components",
                    "creation_time": "2024-01-01T00:00:00Z",
                    "creator": "tester@suse.com",
                    "deadline": None,
                    "depends_on": [],
                    "id": 1,
                    "is_cc_accessible": True,
                    "is_confirmed": True,
                    "is_creator_accessible": True,
                    "is_open": True,
                    "priority": "P3 - Medium",
                    "product": "Test Product",
                    "remaining_time": 0,
                    "resolution": "",
                    "severity": "Normal",
                    "status": "CONFIRMED",
                    "summary": "Test BSC 1",
                    "version": "Test"
                },
                {
                    "classification": "Test",
                    "component": "Test components",
                    "creation_time": "2024-02-02T00:00:00Z",
                    "creator": "tester@suse.com",
                    "deadline": None,
                    "depends_on": [],
                    "id": 2,
                    "is_cc_accessible": True,
                    "is_confirmed": True,
                    "is_creator_accessible": True,
                    "is_open": True,
                    "priority": "P2 - High",
                    "product": "Test Product",
                    "remaining_time": 0,
                    "resolution": "",
                    "severity": "Critical",
                    "status": "CONFIRMED",
                    "summary": "Test BSC 2",
                    "version": "Test"
                },
            ],
            "Test Product in Public Clouds": [
                {
                    "classification": "Test",
                    "component": "Test components",
                    "creation_time": "2024-03-03T00:00:00Z",
                    "creator": "tester@suse.com",
                    "deadline": None,
                    "depends_on": [],
                    "id": 3,
                    "is_cc_accessible": True,
                    "is_confirmed": True,
                    "is_creator_accessible": True,
                    "is_open": True,
                    "priority": "P4 - Low",
                    "product": "Test Product",
                    "remaining_time": 0,
                    "resolution": "",
                    "severity": "Low",
                    "status": "CONFIRMED",
                    "summary": "Test BSC 3",
                    "version": "Test"
                }
            ]
        }
        
    def test_parse_cli_args_default_values(self):
        # missing required api key
        sys.argv = ['bsc_finder.py']
        with self.assertRaises(SystemExit) as cm:
            parse_cli_args()
            self.assertEqual(cm.exception.code, 2)
            self.assertIn("error: the following arguments are required: -t/--api-key", cm.msg)

        sys.argv = ['bsc_finder.py', "-k", "test_key"]
        args = parse_cli_args()

        self.assertEqual(args.api_key, "test_key")
        self.assertFalse(args.all)
        self.assertEqual(args.product_version, "4.3")
        self.assertFalse(args.cloud)
        self.assertIsNone(args.status)
        self.assertIsNone(args.resolution)
        self.assertIsNone(args.output_file)
        self.assertEqual(args.output_format, "txt")

    def test_parse_cli_args_success(self):
        # shorthand flags
        sys.argv = ['bsc_finder.py', "-k", "test_key", "-a", "-p", "5.0", "-c", "-s", "CONFIRMED", "-r", "", "-o", "test.json", "-f", "json"]
        args = parse_cli_args()

        self.assertEqual(args.api_key, "test_key")
        self.assertTrue(args.all)
        self.assertEqual(args.product_version, "5.0")
        self.assertTrue(args.cloud)
        self.assertEqual(args.status, "CONFIRMED")
        self.assertEqual(args.resolution, '')
        self.assertEqual(args.output_file, "test.json")
        self.assertEqual(args.output_format, "json")

        # long flags
        sys.argv = [
            "bsc_finder.py", "--api-key", "test_key", "--all", "--product-version", "5.0", "--cloud", "-s", "CONFIRMED",
            "--resolution", "", "--output", "test.json", "--format", "json"
        ]
        args = parse_cli_args()

        self.assertEqual(args.api_key, "test_key")
        self.assertTrue(args.all)
        self.assertEqual(args.product_version, "5.0")
        self.assertTrue(args.cloud)
        self.assertEqual(args.status, "CONFIRMED")
        self.assertEqual(args.resolution, '')
        self.assertEqual(args.output_file, "test.json")
        self.assertEqual(args.output_format, "json")
    
    def test_get_suma_product_name(self):
        result: str = get_suma_product_name("5.0", False)
        self.assertEqual(result, "SUSE Manager 5.0")
        result: str = get_suma_product_name("5.0", True)
        self.assertEqual(result, "SUSE Manager 5.0 in Public Clouds")

    def test_get_suma_bugzilla_products(self):
        # only version, no cloud
        product_names: list[str] = get_suma_bugzilla_products(False, "4.3", False)
        self.assertListEqual(product_names, ["SUSE Manager 4.3"])
        # version and cloud
        product_names: list[str] = get_suma_bugzilla_products(False, "5.0", True)
        self.assertListEqual(product_names, ["SUSE Manager 5.0 in Public Clouds"])
        # all
        product_names: list[str] = get_suma_bugzilla_products(True, "whatever", True)
        self.assertListEqual(product_names, [
                "SUSE Manager 4.3",
                "SUSE Manager 4.3 in Public Clouds",
                "SUSE Manager 5.0",
                "SUSE Manager 5.0 in Public Clouds"
            ]
        )

    def test_bugs_to_link_list(self):
        expected_output: list[str] = [
            "## Test Product\n\n",
            f"- [ ] [Bug 1]({self.bugzilla_client.show_bug_url}?id=1) - P3 - Medium - (Test components) Test BSC 1\n",
            f"- [ ] [Bug 2]({self.bugzilla_client.show_bug_url}?id=2) - P2 - High - (Test components) Test BSC 2\n",
            "\n",
            "## Test Product in Public Clouds\n\n",
            f"- [ ] [Bug 3]({self.bugzilla_client.show_bug_url}?id=3) - P4 - Low - (Test components) Test BSC 3\n",
            "\n"
        ]

        links_list: list[str] = bugs_to_links_list(self.mock_bugs, self.bugzilla_client.show_bug_url)
        self.assertListEqual(links_list, expected_output)

    def test_store_results(self):
        test_output_json_file: str = 'test_bsc_list.json'
        test_output_txt_file: str = 'test_bsc_list.txt'

        # JSON output
        store_results(self.mock_bugs, test_output_json_file, "json")
        self.assertTrue(path.isfile(test_output_json_file))
        with open(test_output_json_file) as json_output:
            output_json: dict[str, dict[str, str]] = json.load(json_output)
            self.assertDictEqual(self.mock_bugs, output_json)

        # cleanup
        remove(test_output_json_file)
        
        # TXT output
        expected_output: list[str] = [
            "## Test Product\n",
            "\n",
            f"- [ ] [Bug 1]({self.bugzilla_client.show_bug_url}?id=1) - P3 - Medium - (Test components) Test BSC 1\n",
            f"- [ ] [Bug 2]({self.bugzilla_client.show_bug_url}?id=2) - P2 - High - (Test components) Test BSC 2\n",
            "\n",
            "## Test Product in Public Clouds\n",
            "\n",
            f"- [ ] [Bug 3]({self.bugzilla_client.show_bug_url}?id=3) - P4 - Low - (Test components) Test BSC 3\n",
            "\n"
        ]

        store_results(self.mock_bugs, test_output_txt_file, "txt", self.bugzilla_client.show_bug_url)
        self.assertTrue(path.isfile(test_output_txt_file))
        with open(test_output_txt_file) as txt_file:
            lines: list[str] = txt_file.readlines()
            self.assertListEqual(lines, expected_output)

        # cleanup
        remove(test_output_txt_file)
