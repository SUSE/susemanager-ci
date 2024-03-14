from requests import HTTPError
import unittest
from unittest.mock import patch

from tests.mock_response import MockResponse
from json_generator.smash_client import SmashClient


class SmashClientTestCase(unittest.TestCase):

    @patch('requests.get')
    def test_get_embargoed_bugs_ids_success(self, mock_requests_get):
        mock_requests_get.side_effect = _mock_requests_get_success
        smash_client: SmashClient = SmashClient()

        first_call_ids: set[str] = smash_client.get_embargoed_bugs_ids()
        # 1 CVE and 3 bnc expected
        self.assertEqual(len({id for id in first_call_ids if id.startswith("CVE-")}), 1)
        self.assertEqual(len({id for id in first_call_ids if id.startswith("bnc#")}), 3)

        second_call_ids: set[str] = smash_client.get_embargoed_bugs_ids()
        # requests.get is only called by get_embargoed_bugs_ids when the result has not been previously stored in embargoed_ids_cache,
        # therefore we can check the number of times it gets called to verify if there was a cache hit
        mock_requests_get.assert_called_once()
        # ids should have been cached so the sets diff should be empty
        self.assertEqual(len(first_call_ids.difference(second_call_ids)), 0)

    @patch('requests.get')
    def test_get_embargoed_bugs_ids_failure(self, mock_requests_get):
        mock_requests_get.side_effect = _mock_requests_get_fail
        smash_client: SmashClient = SmashClient()

        self.assertRaises(HTTPError, smash_client.get_embargoed_bugs_ids)

def _mock_requests_get_success(*args):
    with open('./tests/testdata/smash_embargoed_bugs.json') as smash_embargo_json:
        json_content: str = smash_embargo_json.read()
        return MockResponse(200, True, json_content)
    
def _mock_requests_get_fail(*args):
    return MockResponse(500, False)

if __name__ == '__main__':
    unittest.main()
