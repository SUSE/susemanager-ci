import json
from requests import HTTPError
from typing import Any

from json_generator.maintenance_json_generator import IBS_MAINTENANCE_URL_PREFIX
from json_generator.smash_client import SMASH_EMBARGO_ENDPOINT


class MockResponse:
    def __init__(self, status_code: int, ok: bool, content:str=''):
        self.status_code = status_code
        self.ok = ok
        self.content = content

    def json(self) -> Any:
        return json.loads(self.content)
    
    def raise_for_status(self):
        raise HTTPError()

def mock_requests_get_success(*args) -> MockResponse:
    if args[0] == f"{IBS_MAINTENANCE_URL_PREFIX}1234/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/":
        return MockResponse(200, True)
    elif args[0] == SMASH_EMBARGO_ENDPOINT:
        with open('./tests/testdata/smash_embargoed_bugs.json') as smash_embargo_json:
            json_content: str = smash_embargo_json.read()
            return MockResponse(200, True, json_content)
    return MockResponse(404, False)

def mock_requests_get_fail(*args) -> MockResponse:
    return MockResponse(500, False)
