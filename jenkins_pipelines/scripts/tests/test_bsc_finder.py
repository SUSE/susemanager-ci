import sys
import unittest

from bsc_list_generator.bsc_finder import parse_cli_args, get_bugzilla_product, bugs_to_links_list, BUGZILLA_SHOW_BUG_URL

class BscFinderTestCase(unittest.TestCase):
        
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
    
    def test_get_bugzilla_product(self):
        result: str = get_bugzilla_product("5.0", False)
        self.assertEqual(result, "SUSE Manager 5.0")
        result: str = get_bugzilla_product("5.0", True)
        self.assertEqual(result, "SUSE Manager 5.0 in Public Clouds")

    def test_bugs_to_link_list(self):
        mock_bugs: dict[str, list[dict]] = {
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

        expected_output: list[str] = [
            "## Test Product\n\n",
            f"- [ ] [Bug 1]({BUGZILLA_SHOW_BUG_URL}?id=1) - P3 - Medium - (Test components) Test BSC 1\n",
            f"- [ ] [Bug 2]({BUGZILLA_SHOW_BUG_URL}?id=2) - P2 - High - (Test components) Test BSC 2\n",
            "\n",
            "## Test Product in Public Clouds\n\n",
            f"- [ ] [Bug 3]({BUGZILLA_SHOW_BUG_URL}?id=3) - P4 - Low - (Test components) Test BSC 3\n",
            "\n"
        ]

        links_list: list[str] = bugs_to_links_list(mock_bugs)
        self.assertListEqual(links_list, expected_output)