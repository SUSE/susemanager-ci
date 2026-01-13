import unittest

from bsc_list_generator.bsc_finder import get_bugzilla_product

class BugzillaClientTestCase(unittest.TestCase):
    
    def test_get_bugzilla_product(self):
        result: str = get_bugzilla_product("5.0", False)
        self.assertEqual(result, "SUSE Manager 5.0")
        result: str = get_bugzilla_product("5.0", True)
        self.assertEqual(result, "SUSE Manager 5.0 in Public Clouds")