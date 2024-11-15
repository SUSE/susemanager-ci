import requests
from typing import Any

_SUSE_BUGZILLA_BASE_URL = "https://bugzilla.suse.com"

class BugzillaClient:

    # api_key is needed for actual API calls
    def __init__(self, api_key: str, base_url: str = _SUSE_BUGZILLA_BASE_URL, api_type: str = "rest"):
        if not api_key:
            raise ValueError("api_key is None or empty")
        # private
        self._api_key: str = api_key
        self._base_url: str = base_url
        self._api_url: str = f"{base_url}/{api_type}"
        self._bugs_endpoint = f"{base_url}/{api_type}/bug"
        self._params: dict[str, Any] = { 'Bugzilla_api_key': self._api_key }
        # public 
        self.show_bug_url: str = f"{base_url}/show_bug.cgi"

    def get_bugs(self, **kwargs) -> list[dict[str, Any]]:
        # drops CLI args that have not beend used and have no default
        additional_params: dict[str, Any] = { k: v for k, v in kwargs.items() if v is not None }
        response: requests.Response = requests.get(self._bugs_endpoint, params={**self._params, **additional_params})
        if not response.ok:
            response.raise_for_status()

        json_res: dict = response.json()
        bugs: list[dict[str, Any]] = json_res['bugs']
        return bugs
    
