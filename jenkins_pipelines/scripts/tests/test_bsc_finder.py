import sys
import unittest

from bsc_list_generator.bsc_finder import parse_cli_args, get_bugzilla_product

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