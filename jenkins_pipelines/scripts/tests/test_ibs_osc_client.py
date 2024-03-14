from datetime import datetime, timezone
import xml.etree.ElementTree as ET
from subprocess import CalledProcessError
import unittest
from unittest.mock import patch

from json_generator.ibs_osc_client import IbsOscClient
from tests.mock_response import mock_requests_get_success

_TEST_EMBARGO_PATCHINFO_PATH: str = './tests/testdata/_patchinfo_with_embargo'
_TEST_NO_EMBARGO_PATCHINFO_PATH: str = './tests/testdata/_patchinfo_no_embargo'

class IbsOscClientTestCase(unittest.TestCase):

    def setUp(self):
        self.ibs_client: IbsOscClient = IbsOscClient()

    def test_osc_command_success(self):
        version:str = self.ibs_client._osc_command('version')
        # as an example:
        # '1.6.1\n' --> [1, 6, 1] --> [True, True, True] --> all([True, True, True]) will return True
        self.assertTrue(all([char.isdigit() for char in version.replace('\n', '').split('.')]))
    
    def test_osc_command_failure(self):
        self.assertRaises(CalledProcessError, self.ibs_client._osc_command, '')
        self.assertRaises(CalledProcessError, self.ibs_client._osc_command, 'something')
        # invalid subcommands
        self.assertRaises(CalledProcessError, self.ibs_client._osc_command, 'meta attr')
        self.assertRaises(CalledProcessError, self.ibs_client._osc_command, 'meta attribute')
        self.assertRaises(CalledProcessError, self.ibs_client._osc_command, 'checkout -x')
        self.assertRaises(CalledProcessError, self.ibs_client._osc_command, 'checkout SUSE:Maintenance:0000')

    def test_parse_embargo_date(self):
        test_date: datetime = datetime.now(tz=timezone.utc)

        test_cases: list[tuple[str, bool]] = [
            *((format, False) for format in IbsOscClient._EMBARGO_END_DATE_FORMATS),
            ('%d-%m-%Y', True),
        ]
        
        for date_format, expected_failure in test_cases:
            date_text: str = test_date.strftime(date_format)
            if expected_failure:
                self.assertRaises(ValueError, self.ibs_client._parse_embargo_date, date_text)
            else:
                self.ibs_client._parse_embargo_date(date_text)

    def test_parse_xml_issue(self):
        bugzilla_issue_text: str = '<issue id="1234567" tracker="bnc"></issue>'
        bugzilla_issue_xml: ET.Element = ET.fromstring(bugzilla_issue_text)
        bugzilla_issue_id: str = self.ibs_client._parse_xml_issue(bugzilla_issue_xml)
        self.assertEqual(bugzilla_issue_id, "bnc#1234567")

        cve_issue_text: str = '<issue id="2021-00001" tracker="cve" />'
        cve_issue_xml: ET.Element = ET.fromstring(cve_issue_text)
        cve_issue_id: str = self.ibs_client._parse_xml_issue(cve_issue_xml)
        self.assertEqual(cve_issue_id, "CVE-2021-00001")

    def test_get_patchinfo_issues_ids(self):
        ids: set [str] = self.ibs_client._get_patchinfo_issues_ids(_TEST_EMBARGO_PATCHINFO_PATH)
        # 4 CVE and 4 bnc expected
        self.assertEqual(len({id for id in ids if id.startswith("CVE-")}), 4)
        self.assertEqual(len({id for id in ids if id.startswith("bnc#")}), 4)

    # decorators will be applied bottom-up, args order is in reverse
    @patch.object(IbsOscClient, '_checkout_mi_patchinfo')
    @patch('requests.get')
    def test_mi_has_issues_under_embargo(self, mock_api_call, mock_client_method):
        mock_api_call.side_effect = mock_requests_get_success
        mock_client_method.side_effect = _mock_checkout_mi_patchinfo

        self.assertTrue(self.ibs_client._mi_has_issues_under_embargo('12345'))
        self.assertFalse(self.ibs_client._mi_has_issues_under_embargo('56789'))


def _mock_checkout_mi_patchinfo(*args) -> str:
    if args[0] == "12345":
        return _TEST_EMBARGO_PATCHINFO_PATH
    elif args[0] == "56789":
        return _TEST_NO_EMBARGO_PATCHINFO_PATH
    return ""
    

if __name__ == '__main__':
    unittest.main()
