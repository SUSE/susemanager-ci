import os
import sys
import unittest

current_dir = os.path.dirname(os.path.abspath(__file__))
target_module_path = os.path.abspath(os.path.join(current_dir, '..', 'json_generator'))
if target_module_path not in sys.path:
    sys.path.insert(0, target_module_path)

import hub_release_repositories as h

DESCRIPTION_51 = """
|SLE 15-SP7|updated extensions|{color:#de350b}NOT READY{color}|SUSE:Maintenance:46932| |
|SLE 15-SP7 and SL Micro 6.1|containers|{color:#de350b}NOT READY{color}|SUSE:Maintenance:46932|General filter: x|
"""
DESCRIPTION_52 = "|EL 10|x|SUSE:Maintenance:47441|\n|Ubuntu|x|SUSE:Maintenance:47565|\n|EL 9|x|SUSE:Maintenance:47441|"


def issue(key, summary, description):
    return {"key": key, "fields": {"summary": summary, "description": description, "status": {"name": "In Progress"}}}


class TestParse(unittest.TestCase):

    def test_release_and_mis_from_ticket(self):
        t = h.parse_ticket(issue("MSQA-1061", "SUSE Multi-Linux Manager 5.1 - 5.1.6 MU", DESCRIPTION_51))
        self.assertEqual(t["release"], "5.1")
        self.assertEqual(t["mi_ids"], ["46932"])
        self.assertEqual(t["not_ready"], 2)

    def test_mis_are_deduplicated_in_order(self):
        t = h.parse_ticket(issue("MSQA-1062", "SUSE Multi-Linux Manager 5.2 - 5.2.2", DESCRIPTION_52))
        self.assertEqual(t["mi_ids"], ["47441", "47565"])

    def test_unknown_release_needs_override(self):
        with self.assertRaises(SystemExit):
            h.parse_ticket(issue("MSQA-1", "Something else", ""))
        t = h.parse_ticket(issue("MSQA-1", "Something else", ""), "5.2")
        self.assertEqual(t["release"], "5.2")

    def test_ticket_key_accepts_url_and_override(self):
        self.assertEqual(h.ticket_key("https://jira.suse.com/browse/MSQA-1062"), ("MSQA-1062", None))
        self.assertEqual(h.ticket_key("MSQA-1062=5.2"), ("MSQA-1062", "5.2"))
        with self.assertRaises(SystemExit):
            h.ticket_key("nonsense")


class TestPlan(unittest.TestCase):
    T51 = {"release": "5.1", "mi_ids": ["46932"]}
    T52 = {"release": "5.2", "mi_ids": ["47441", "47565"]}

    def test_two_tickets(self):
        plan = h.plan_releases([self.T51, self.T52])
        self.assertEqual(plan["5.1"], ["46932", "47441", "47565"])
        self.assertEqual(plan["5.2"], ["47441", "47565"])

    def test_only_52_ticket_feeds_both_releases(self):
        self.assertEqual(h.plan_releases([self.T52]), {"5.1": ["47441", "47565"], "5.2": ["47441", "47565"]})

    def test_only_51_ticket_gives_no_52_file(self):
        self.assertEqual(h.plan_releases([self.T51]), {"5.1": ["46932"]})

    def test_overlapping_mis_are_listed_once_in_order(self):
        t51 = {"release": "5.1", "mi_ids": ["46932", "47441"]}
        plan = h.plan_releases([t51, self.T52])
        self.assertEqual(plan["5.1"], ["46932", "47441", "47565"])
        self.assertEqual(plan["5.2"], ["47441", "47565"])

    def test_no_ticket_gives_empty_plan(self):
        self.assertEqual(h.plan_releases([]), {})


class TestHelpers(unittest.TestCase):

    def test_proxy_pr_copied_to_transactional_proxies_only(self):
        merged = {
            "slmicro61_minion": {"slfo_pr_9674_slmicro61_x86_64": "u", "other": "x"},
            "proxy_transactional": {"a": "1"}, "proxy_non_transactional": {"b": "2"},
        }
        self.assertTrue(h.apply_proxy_pr(merged, "slmicro61_minion"))
        self.assertIn("slfo_pr_9674_slmicro61_x86_64", merged["proxy_transactional"])
        self.assertNotIn("slfo_pr_9674_slmicro61_x86_64", merged["proxy_non_transactional"])
        self.assertNotIn("other", merged["proxy_transactional"])

    def test_proxy_pr_without_entry_reports_false(self):
        self.assertFalse(h.apply_proxy_pr({"proxy_transactional": {}}, "slmicro61_minion"))

    def test_per_release(self):
        self.assertEqual(h.per_release(["5.1=1,2", "5.2=3", "5.1=4"], "x"), {"5.1": ["1", "2", "4"], "5.2": ["3"]})
        with self.assertRaises(SystemExit):
            h.per_release(["6.0=1"], "x")

    def test_args_need_exactly_one_source(self):
        with self.assertRaises(SystemExit):
            h.parse_args([])
        with self.assertRaises(SystemExit):
            h.parse_args(["--jira", "MSQA-1", "--mi-ids", "1"])


if __name__ == "__main__":
    unittest.main()
