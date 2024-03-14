import unittest
from unittest.mock import patch

from json_generator.maintenance_json_generator import create_url, IBS_MAINTENANCE_URL_PREFIX
from tests.mock_response import MockResponse


class MaintenanceJsonGeneratorTestCase(unittest.TestCase):
    
    @patch('requests.get')
    def test_create_url(self, mock_requests_get):
        mock_requests_get.side_effect = _mock_create_url_requests_get

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
    def test_create_url_cache(self, mock_requests_get):
        create_url.cache_clear()
        # requests.get is only called by create_url when the results is not present in the LRU cache,
        # therefore we can check the number of times it gets called to verify if there was a cache hit
        mock_requests_get.side_effect = _mock_create_url_requests_get

        ids: set[str] = {"1234", "5678", "9012"}
        suffixes: set[str] = {"/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/", "/some/other/url/"}
        num_entries:int = len(ids)*len(suffixes)
        iterations: int = 3

        # the first iteration should result in all cache misses, the following ones should be all cache hits
        for i in range(iterations):
            for id in ids:
                for suffix in suffixes:
                    create_url(id, suffix)
            self.assertEqual(mock_requests_get.call_count, num_entries, f"Iteration N°{i+1} of {iterations}")
    

# This method will be used by the mock to replace requests.get for create_url calls
def _mock_create_url_requests_get(*args, **kwargs):
    if args[0] == f"{IBS_MAINTENANCE_URL_PREFIX}1234/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/":
        return MockResponse(200, True)
    return MockResponse(404, False)

if __name__ == '__main__':
    unittest.main()
