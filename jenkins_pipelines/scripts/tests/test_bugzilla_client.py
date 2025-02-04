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

        bugs: list[dict[str, Any]] = self.bugzilla_client._get_bugs(product = "Test Product", status = None, release = None)
        mock_api_call.assert_called_once()
        # check None keys are dropped
        mock_api_call.assert_called_with(self.bugzilla_client._bugs_endpoint, params = {'Bugzilla_api_key': 'test_key', "product": "Test Product"})
        self.assertEqual(len(bugs), 3)
        for i in range(len(bugs)):
            bug: dict[str, Any] = bugs[i]
            self.assertEqual(bug['product'], "Test Product")
            self.assertEqual(bug['id'], i+1)
        
        # just check the arguments are correctly passed when there's a value
        self.bugzilla_client._get_bugs(product = "Test Product", status = "CONFIRMED", release = None)
        mock_api_call.assert_called_with(self.bugzilla_client._bugs_endpoint, params = {'Bugzilla_api_key': 'test_key', "product": "Test Product", "status": "CONFIRMED"})
    
    @patch('requests.get')
    def test_get_bugs_failure(self, mock_api_call):
        mock_api_call.side_effect = mock_requests_get_fail
        self.assertRaises(HTTPError, self.bugzilla_client._get_bugs)

if __name__ == '__main__':
    unittest.main()
