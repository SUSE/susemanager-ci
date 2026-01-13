import requests

_SMASH_API_URL = 'https://smash.suse.de/api'

class SmashClient():

    def __init__(self, api_url:str = _SMASH_API_URL, api_token: str = '') -> None:
        self._api_url: str = api_url
        self._embargo_endpoint: str = f"{api_url}/embargoed-bugs/"
        self._issues_endpoint: str = f"{api_url}/issues/"
        self._missing_subs_endpoint: str = f"{api_url}/issues-missing-submissions/"
        self._embargoed_ids_cache: set[str] = set()
        if api_token:
            self._headers: dict[str, str] = {
                "Authorization": f"Token {api_token}"
            }

    def get_embargoed_bugs_ids(self) -> set[str]:
        if not self._embargoed_ids_cache:
            res: requests.Response = requests.get(self._embargo_endpoint)
            if not res.ok:
                res.raise_for_status()

            bug_ids: set[str] = set()
            json_content: list[dict] = res.json()
            for item in json_content:
                bug_ids.add(item['bug']['name'])
                bug_ids.update({ cve['name'] for cve in item.get('cves', set()) })

            self._embargoed_ids_cache = bug_ids

        return self._embargoed_ids_cache
    
    def get_issues(self, missing_subs=False, **kwargs) -> list[dict]:
        issues: list[dict] = []
        all_pages: bool = kwargs.get("all", False)

        endpoint: str = self._missing_subs_endpoint if missing_subs else self._issues_endpoint
        res: requests.Response = requests.get(endpoint, params=kwargs, headers=self._headers)
        if not res.ok:
            res.raise_for_status()
        
        json_content : list[dict] = res.json()
        issues.extend(json_content['results'])

        while all_pages and json_content["next"]:
            next_page_url: str = json_content["next"]
            print(f"GET new page of results - {next_page_url}")

            res = requests.get(next_page_url, headers=self._headers)
            if not res.ok:
                res.raise_for_status()

            json_content = res.json()
            issues.extend(json_content['results'])

        return issues
