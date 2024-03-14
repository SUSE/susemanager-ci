import json
from requests import HTTPError
from typing import Any


class MockResponse:
    def __init__(self, status_code: int, ok: bool, content:str=''):
        self.status_code = status_code
        self.ok = ok
        self.content = content

    def json(self) -> Any:
        return json.loads(self.content)
    
    def raise_for_status(self):
        raise HTTPError()
