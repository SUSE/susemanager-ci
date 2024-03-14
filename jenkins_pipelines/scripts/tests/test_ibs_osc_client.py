from datetime import datetime, timezone
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

if __name__ == '__main__':
    unittest.main()
