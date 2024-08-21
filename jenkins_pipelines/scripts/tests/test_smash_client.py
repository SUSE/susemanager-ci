from requests import HTTPError
import unittest
from unittest.mock import patch

from tests.mock_response import mock_requests_get_success, mock_requests_get_fail
from json_generator.smash_client import SmashClient


class SmashClientTestCase(unittest.TestCase):

    def setUp(self):
        self.smash_client: SmashClient = SmashClient()

    @patch('requests.get')
    def test_get_embargoed_bugs_ids_success(self, mock_api_call):
        mock_api_call.side_effect = mock_requests_get_success

        first_call_ids: set[str] = self.smash_client.get_embargoed_bugs_ids()
        # 1 CVE and 3 bnc expected
        self.assertEqual(len({id for id in first_call_ids if id.startswith("CVE-")}), 1)
        self.assertEqual(len({id for id in first_call_ids if id.startswith("bnc#")}), 3)

        second_call_ids: set[str] = self.smash_client.get_embargoed_bugs_ids()
        # requests.get is only called by get_embargoed_bugs_ids when the result has not been previously stored in embargoed_ids_cache,
        # therefore we can check the number of times it gets called to verify if there was a cache hit
        mock_api_call.assert_called_once()
        # ids should have been cached so the sets diff should be empty
        self.assertEqual(len(first_call_ids.difference(second_call_ids)), 0)

    @patch('requests.get')
    def test_get_embargoed_bugs_ids_failure(self, mock_api_call):
        mock_api_call.side_effect = mock_requests_get_fail
        self.assertRaises(HTTPError, self.smash_client.get_embargoed_bugs_ids)
    
if __name__ == '__main__':
    unittest.main()
