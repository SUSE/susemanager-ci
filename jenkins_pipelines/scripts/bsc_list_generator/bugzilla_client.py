import logging
from os import remove
import subprocess
import requests
from typing import Any

_SUSE_BUGZILLA_BASE_URL = "https://bugzilla.suse.com"
_IBS_API_URL: str = "https://api.suse.de"

class BugzillaClient:

    def __init__(self, api_key: str, base_url: str = _SUSE_BUGZILLA_BASE_URL, api_type: str = "rest"):
        # api_key is needed for actual API calls so we may as well fail here
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

    def find_suma_bscs(self, bugzilla_products: list[str], **kwargs) -> dict[str, list[dict[str, Any]]]:
        product_bugs: dict[str, list[dict[str, Any]]] = {}

        for bugzilla_product in bugzilla_products:
            logging.info(f"Retrieving BSCs for product '{bugzilla_product}'...")
            product_bugs[bugzilla_product] = self._get_bugs(product = bugzilla_product, **kwargs)
            logging.info("Done")

        return product_bugs
    
    def bscs_from_release_notes(self, release_note_paths: tuple[tuple[str, str, str]], **kwarg) -> list[dict[str, Any]]:
        bsc_ids: list[str] = []

        for rn_path in release_note_paths:
            rn_ids: list[str] = self._get_mentioned_bscs(*rn_path)
            # avoid duplicating a BSC between Proxy and Server
            for id in rn_ids:
                if id not in bsc_ids:
                    bsc_ids.append(id)
        
        return self._get_bugs(id=','.join(bsc_ids), **kwarg)

    def _get_mentioned_bscs(self, project: str, package:str, filename: str) -> list[str]:
        cmd: str = f"co {project} {package} {filename}"
        # check=True -> raise subprocess.CalledProcessError if the return code is != 0
        result: subprocess.CompletedProcess[bytes] = subprocess.run(
            [f"osc --apiurl {_IBS_API_URL} {cmd}"],
            shell=True, check=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        bugs_ids: list[str] = self._parse_release_notes(filename)
        # cleanup
        remove(filename)

        return bugs_ids

    def _parse_release_notes(self, notes_filename: str) -> list[str]:
        bsc_ids: list[str] = []
        # retrieve BSC IDs only for the latest release notes block
        with open(notes_filename) as nf:
            # first line should delimit a block, better bail out if not
            firstline: str = nf.readline().strip()
            if not len(firstline) or not all(char == '-' for char in firstline):
                print(firstline)
                raise ValueError("Irregular or missing release notes block: first line should only be composed by '-'")
            
            bsc_block: bool = False
            while(True):
                cur_line: str = nf.readline().strip()

                if cur_line.startswith("bsc#"):
                    bsc_block = True
                    bsc_entries: str = cur_line.split(", ")
                    bsc_ids.extend([entry.replace("bsc#", "") for entry in bsc_entries])
                    continue
                
                # this is True only only if we have ended parsing a previous bsc block
                if bsc_block:
                    break

        return bsc_ids
            
    def _get_bugs(self, **kwargs) -> list[dict[str, Any]]:
        # drops CLI args that have not been used and have no default
        additional_params: dict[str, Any] = { k: v for k, v in kwargs.items() if v is not None }
        response: requests.Response = requests.get(self._bugs_endpoint, params={**self._params, **additional_params})
        if not response.ok:
            response.raise_for_status()

        json_res: dict = response.json()
        bugs: list[dict[str, Any]] = json_res['bugs']
        return bugs
