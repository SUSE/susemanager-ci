import json
import requests
from typing import Any

BUGZILLA_BASE_URL = "https://bugzilla.suse.com"
BUGZILLA_SHOW_BUG_URL = f"{BUGZILLA_BASE_URL}/show_bug.cgi"
BUGZILLA_API_URL = f"{BUGZILLA_BASE_URL}/rest"
BUGZILLA_BUGS_ENDPOINT = f"{BUGZILLA_API_URL}/bug"

class BugzillaClient:

    def __init__(self, api_key):
        self.base_url: str = BUGZILLA_API_URL
        self.api_key: str = api_key
        self.params: dict[str, Any] = { 'Bugzilla_api_key': self.api_key }

    def get_bugs(self, **kwargs) -> list[dict[str, Any]]:
        response: requests.Response = requests.get(BUGZILLA_BUGS_ENDPOINT, params={**self.params, **kwargs})
        if not response.ok:
            response.raise_for_status()

        json_res: dict = response.json()
        bugs: list[dict[str, Any]] = json_res['bugs']
        return bugs