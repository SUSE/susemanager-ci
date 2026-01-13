import requests
from enum import StrEnum

SMASH_API_URL = 'https://smash.suse.de/api'
SMASH_EMBARGO_ENDPOINT= f"{SMASH_API_URL}/embargoed-bugs/"
SMASH_ISSUES_ENDPOINT = f"{SMASH_API_URL}/issues"

class Categories(StrEnum):
    MAINTENANCE = "maintenance"
    SECURITY = "security"

class State(StrEnum): 
    NEW = "new"
    IGNORE = "ignore"
    NOT_FOR_US = "not-for-us"
    ANALYSIS = "analysis"
    ANALYZED = "analyzed"
    RESOLVED = "resolved"
    DELETED = "deleted"
    MERGED = "merged"
    POSTPONED = "postponed"
    REVISIT = "revisit"

class Severity(StrEnum):
    NOT_SET = "not-set"
    CRITICAL = "critical"
    IMPORTANT = "important"
    MODERATE = "moderate"
    LOW = "low"

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
    
    def get_issues(self, **kwargs) -> list[dict]:
        res: requests.Response = requests.get(SMASH_ISSUES_ENDPOINT, params=kwargs, headers=self._headers)
        if not res.ok:
            res.raise_for_status()

        json_content : list[dict] = res.json()
        return json_content['results']
    
    def _issue_to_bsc_link(self, issue: dict[str, any]) -> str:
        for ref in issue['references']:
            if ref['source'] == 'SUSE Bugzilla':
                bsc_num: str = ref['name'].split("#")[1]
                return f"- [ ] [Bug {bsc_num}]({ref['url']}) - {issue['summary']}\n"
        raise ValueError(f"No Bugzilla reference for issue {issue['name']}- {issue['summary']}")
        

    def get_bsc_links_list(self, **kwargs) -> list[str]:
        issues: list[dict] = self.get_issues(**kwargs)

        return [ self._issue_to_bsc_link(issue) for issue in issues ]

