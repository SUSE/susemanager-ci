import json
import os
import sys
import tempfile
import unittest

current_dir = os.path.dirname(os.path.abspath(__file__))
target_module_path = os.path.abspath(os.path.join(current_dir, '..', 'json_generator'))
if target_module_path not in sys.path:
    sys.path.insert(0, target_module_path)

import merge_hub_repositories as m

SLES = {
    "server": {"46386": "sles-server", "mlm52_sles_totest_images_sp7": "sles-image"},
    "proxy": {"46393": "sles-proxy-tools"},
    "sles15sp7_minion": {"46215": "minion-a"},
    "ubuntu2404_minion": {"46374": "minion-u"},
}
MICRO = {
    "server": {"slfo_pr_65_server_uyuni_tools": "micro-server"},
    "proxy": {"slmicro6_client_tools": "micro-proxy-tools"},
    "sles15sp7_minion": {"46215": "minion-a"},
    "ubuntu2404_minion": {"46374": "minion-u"},
}


class TestMerge(unittest.TestCase):

    def test_server_and_proxy_are_relabelled_per_variant(self):
        merged = m.merge(SLES, MICRO)
        self.assertEqual(merged["server_non_transactional"], SLES["server"])
        self.assertEqual(merged["proxy_non_transactional"], SLES["proxy"])
        self.assertEqual(merged["server_transactional"], MICRO["server"])
        self.assertEqual(merged["proxy_transactional"], MICRO["proxy"])

    def test_flat_keys_are_the_micro_ones(self):
        merged = m.merge(SLES, MICRO)
        self.assertEqual(merged["server"], MICRO["server"])
        self.assertEqual(merged["proxy"], MICRO["proxy"])

    def test_shared_minion_keys_are_kept_once(self):
        merged = m.merge(SLES, MICRO)
        self.assertEqual(merged["sles15sp7_minion"], {"46215": "minion-a"})
        self.assertEqual(merged["ubuntu2404_minion"], {"46374": "minion-u"})

    def test_differing_minion_key_warns_and_keeps_micro(self):
        micro = {**MICRO, "sles15sp7_minion": {"46215": "changed"}}
        with self.assertLogs(level="WARNING") as logs:
            merged = m.merge(SLES, micro)
        self.assertEqual(merged["sles15sp7_minion"], {"46215": "changed"})
        self.assertIn("sles15sp7_minion", logs.output[0])

    def test_minion_key_only_in_one_run_is_kept(self):
        sles = {**SLES, "sles12sp5_minion": {"46410": "only-sles"}}
        self.assertEqual(m.merge(sles, MICRO)["sles12sp5_minion"], {"46410": "only-sles"})

    def test_missing_server_in_sles_run_only_skips_the_non_transactional_key(self):
        sles = {k: v for k, v in SLES.items() if k != "server"}
        merged = m.merge(sles, MICRO)
        self.assertNotIn("server_non_transactional", merged)
        self.assertEqual(merged["server_transactional"], MICRO["server"])

    def test_cli_writes_the_merged_file(self):
        with tempfile.TemporaryDirectory() as d:
            paths = {n: os.path.join(d, f"{n}.json") for n in ("sles", "micro", "out")}
            for n, data in (("sles", SLES), ("micro", MICRO)):
                with open(paths[n], "w") as f:
                    json.dump(data, f)
            m.main(["--sles", paths["sles"], "--micro", paths["micro"], "--output", paths["out"]])
            with open(paths["out"]) as f:
                self.assertEqual(json.load(f), m.merge(SLES, MICRO))


if __name__ == '__main__':
    unittest.main()
