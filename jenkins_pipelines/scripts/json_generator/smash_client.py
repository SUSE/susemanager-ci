import requests

SMASH_API_URL = 'https://smash.suse.de/api'
SMASH_API_V2_URL = "https://smash.suse.de/api2"
SMASH_EMBARGO_ENDPOINT= f"{SMASH_API_URL}/embargoed-bugs/"
SMASH_ISSUES_ENDPOINT = f"{SMASH_API_URL}/issues/"
SMASH_MISSING_SUBMISSIONS_ENDPOINT = f"{SMASH_API_URL}/issues-missing-submissions/"

class SmashClient():

    def __init__(self, api_token: str = '') -> None:
        self._embargoed_ids_cache: set[str] = set()
        if api_token:
            self._headers: dict[str, str] = {
                "Authorization": f"Token {api_token}"
            }

    def get_embargoed_bugs_ids(self) -> set[str]:
        if not self._embargoed_ids_cache:
            res: requests.Response = requests.get(SMASH_EMBARGO_ENDPOINT)
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

        endpoint: str = SMASH_MISSING_SUBMISSIONS_ENDPOINT if missing_subs else SMASH_ISSUES_ENDPOINT
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
    

