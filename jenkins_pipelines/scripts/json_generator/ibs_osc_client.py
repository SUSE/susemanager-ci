from datetime import date, datetime
import logging
import xml.etree.ElementTree as ET
from shutil import copyfile, rmtree
import subprocess
from os import getcwd, path

from smash_client import SmashClient


IBS_API_URL: str = 'https://api.suse.de'

class IbsOscClient():
    # TODO: verify if this covers all possible formats for MIs under embargo
    _EMBARGO_END_DATE_FORMATS: set[str] = {'%Y-%m-%d %H:%M %Z', '%Y-%m-%d'}
    
    def __init__(self) -> None:
        self._api_url: str = IBS_API_URL
        self._current_date: date = date.today()
        self._smash_client = SmashClient()

    def find_maintenance_incidents(self, status: str = 'open', group: str = 'qam-manager') -> set[str]:
        cmd: str = f"qam {status}"
        if group:
            cmd += f" -G {group}"
        # TODO Find a better way to query the open requests, this is fragile because it depends on external utils
        # being there
        output: str = self._osc_command(cmd)
        lines: list[str] = output.splitlines()
        # Create a set of the maintenance incidents from the output
        mi_ids: set[str] = { line.rstrip().split(sep=':')[3] for line in lines if 'ReviewRequest' in line }
        return mi_ids
    
    def mi_is_under_embargo(self, mi_id: str, patchinfo_check: bool = True) -> bool:
        logging.info(f"MI {mi_id} - checking embargo\n")
        # MI under embargo should have the attribute OBS:EmbargoDate set to the embargo end
        cmd: str = f"meta attribute SUSE:Maintenance:{mi_id}"
        output: str = self._osc_command(cmd)
        xml_attributes: ET.Element = ET.fromstring(output)

        embargo_attribute: ET.Element|None = xml_attributes.find("./attribute[@name='EmbargoDate'][value]")
        if embargo_attribute:
            embargo_attribute_content: str = embargo_attribute.find('./value').text
            embargo_end_date: date = self._parse_embargo_date(embargo_attribute_content)
            if embargo_end_date >= self._current_date:
                logging.info(f"\tMI {mi_id} is under embargo until {embargo_end_date}. Today is {self._current_date}\n")
                return True
            
            logging.info(f"\tMI {mi_id} embargo was lifted after {embargo_end_date}. Today is {self._current_date}")
            if patchinfo_check:
                logging.info("\tDouble checking _patchinfo file for issues under embargo in SMASH ...")
                return self._mi_has_issues_under_embargo(mi_id)

        logging.info(f"\tMI {mi_id} is not under embargo\n")
        return False
    
    def _osc_command(self, cmd: str) -> str:
        # check=True -> raise subprocess.CalledProcessError if the return code is != 0
        result: subprocess.CompletedProcess[bytes] = subprocess.run(
            [f"osc --apiurl {self._api_url} {cmd}"],
            shell=True, check=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        output: str = result.stdout.decode('utf-8')
        return output

    def _parse_embargo_date(self, text: str) -> date:
        for format in self._EMBARGO_END_DATE_FORMATS:
            try:
                return datetime.strptime(text, format).date()
            except:
                logging.error(f"\tInvalid date format {format} for OBS:EmbargoDate value {text}")
        
        raise ValueError(f"Failed to parse OBS:EmbargoDate value {text} with all available date formats")
    
    def _mi_has_issues_under_embargo(self, mi_id: str) -> bool:
        patchinfo_abs_path: str = self._checkout_mi_patchinfo(mi_id)
        patchinfo_ids: set[str] = self._get_patchinfo_issues_ids(patchinfo_abs_path)
        smash_ids: set[str] = self._smash_client.get_embargoed_bugs_ids()

        embargoed_ids: set[str] = patchinfo_ids.intersection(smash_ids)
        if embargoed_ids:
            logging.info(f"\tMI #{mi_id} patchinfo contains bugs that are still under embargo in SMASH: {embargoed_ids}\n")
            return True
        
        logging.info(f"\tMI #{mi_id} patchinfo contains no bug under embargo in SMASH\n")
        return False
    
    def _checkout_mi_patchinfo(self, mi_id: str) -> str:
        mi_dir: str = f"SUSE:Maintenance:{mi_id}"
        patchinfo_dir: str = f"{mi_dir}/patchinfo"
        cmd: str = f"checkout {patchinfo_dir}"
        # we don't need to parse the output this time
        self._osc_command(cmd)

        # rename and keep only the _patchinfo file, cleanup the rest
        patchinfo_src_path: str = path.join(getcwd(), f"{patchinfo_dir}/_patchinfo")
        patchinfo_dst_path: str = path.join(getcwd(), f"MI_{mi_id}_patchinfo")
        copyfile(patchinfo_src_path, patchinfo_dst_path)
        rmtree(path.join(getcwd(), mi_dir))

        return patchinfo_dst_path
    
    def _get_patchinfo_issues_ids(self, patchinfo_path: str) -> set[str]:
        ids: set[str] = set()
        with open(patchinfo_path) as patchinfo_file:
            content: str = patchinfo_file.read()
            patchinfo_xml: ET.Element = ET.fromstring(content)
            issues: list[ET.Element] = patchinfo_xml.findall('./issue')
            ids = { self._parse_xml_issue(el) for el in issues }
        
        return ids
    
    def _parse_xml_issue(self, issue_xml: ET.Element) -> str:
        issue_id: str = issue_xml.attrib['id']
        tracker: str = issue_xml.attrib['tracker']
        return f"{tracker}#{issue_id}" if tracker == 'bnc' else f"{tracker.upper()}-{issue_id}"
