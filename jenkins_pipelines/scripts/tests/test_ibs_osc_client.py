from datetime import datetime, timezone
import xml.etree.ElementTree as ET
import unittest

from json_generator.ibs_osc_client import IbsOscClient


class IbsOscClientTestCase(unittest.TestCase):

    def test_parse_embargo_date(self):
        ibs_client: IbsOscClient = IbsOscClient()
        test_date: datetime = datetime.now(tz=timezone.utc)

        test_cases: list[tuple[str, bool]] = [
            *((format, False) for format in IbsOscClient._EMBARGO_END_DATE_FORMATS),
            ('%d-%m-%Y', True),
        ]
        
        for date_format, expected_failure in test_cases:
            date_text: str = test_date.strftime(date_format)
            if expected_failure:
                self.assertRaises(ValueError, ibs_client._parse_embargo_date, date_text)
            else:
                ibs_client._parse_embargo_date(date_text)

    def test_parse_xml_issue(self):
        ibs_client: IbsOscClient = IbsOscClient()

        bugzilla_issue_text: str = '<issue id="1234567" tracker="bnc"></issue>'
        bugzilla_issue_xml: ET.Element = ET.fromstring(bugzilla_issue_text)
        bugzilla_issue_id: str = ibs_client._parse_xml_issue(bugzilla_issue_xml)
        self.assertEqual(bugzilla_issue_id, "bnc#1234567")

        cve_issue_text: str = '<issue id="2021-00001" tracker="cve" />'
        cve_issue_xml: ET.Element = ET.fromstring(cve_issue_text)
        cve_issue_id: str = ibs_client._parse_xml_issue(cve_issue_xml)
        self.assertEqual(cve_issue_id, "CVE-2021-00001")

if __name__ == '__main__':
    unittest.main()
