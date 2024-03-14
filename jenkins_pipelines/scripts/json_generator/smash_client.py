import requests


SMASH_EMBARGO_ENDPOINT= 'https://smash.suse.de/api/embargoed-bugs/'

class SmashClient():

    def __init__(self) -> None:
        self._embargoed_ids_cache: set[str] = set()

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
