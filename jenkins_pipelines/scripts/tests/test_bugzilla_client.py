from typing import Any
import unittest
from unittest.mock import patch

from requests import HTTPError

from tests.mock_response import mock_requests_get_success, mock_requests_get_fail
from bsc_list_generator.bugzilla_client import BugzillaClient

class BugzillaClientTestCase(unittest.TestCase):
    
    def setUp(self):
        self.bugzilla_client: BugzillaClient = BugzillaClient("test_key")

    @patch('requests.get')
    def test_get_bugs_success(self, mock_api_call):
        mock_api_call.side_effect = mock_requests_get_success

        bugs: list[dict[str, Any]] = self.bugzilla_client._get_bugs(product = "Test Product", reporter = None, status = None, release = None)
        mock_api_call.assert_called_once()
        # check None keys are dropped
        mock_api_call.assert_called_with(self.bugzilla_client._bugs_endpoint, params = {'Bugzilla_api_key': 'test_key', "product": "Test Product"})
        # embargoed bug should have been dropped
        self.assertEqual(len(bugs), 3)
        for i in range(len(bugs)):
            bug: dict[str, Any] = bugs[i]
            self.assertEqual(bug['product'], "Test Product")
            self.assertEqual(bug['id'], i+1)
        
        # just check the arguments are correctly passed when there's a value
        self.bugzilla_client._get_bugs(product = "Test Product", reporter = None, status = "CONFIRMED", release = None)
        mock_api_call.assert_called_with(self.bugzilla_client._bugs_endpoint, params = {'Bugzilla_api_key': 'test_key', "product": "Test Product", "status": "CONFIRMED"})
    
    @patch('requests.get')
    def test_get_bugs_failure(self, mock_api_call):
        mock_api_call.side_effect = mock_requests_get_fail
        self.assertRaises(HTTPError, self.bugzilla_client._get_bugs)

    def test_parse_release_notes(self):
        bug_ids: list[str] = self.bugzilla_client._parse_release_notes('./tests/testdata/test_release_notes.changes')
        self.assertListEqual(bug_ids, ['1', '2', '3', '4', '5', '6', '7'])

        # first line is not ---------------- 
        self.assertRaises(ValueError, self.bugzilla_client._parse_release_notes, './tests/testdata/test_invalid_release_notes.changes')

    def test_bug_under_embargo(self):
        bsc: dict[str, Any] = {
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
            "priority": "P0 - Critical",
            "product": "Test Product",
            "remaining_time": 0,
            "resolution": "",
            "severity": "High",
            "status": "CONFIRMED",
            "summary": "VUL-0: EMBARGOED: Test BSC",
            "version": "Test"
        }
        # explicit mention in the summary
        self.assertTrue(self.bugzilla_client._bug_under_embargo(bsc))
        # no embargo mention
        bsc['summary'] = "CVE 123456789: Test BSC"
        self.assertFalse(self.bugzilla_client._bug_under_embargo(bsc))
        bsc['summary'] = "Test BSC"
        self.assertFalse(self.bugzilla_client._bug_under_embargo(bsc))

        

if __name__ == '__main__':
    unittest.main()
