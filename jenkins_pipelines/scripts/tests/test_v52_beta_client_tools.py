"""Regression tests for 5.2 beta client-tools URL semantics in v52_nodes."""

import unittest

from repository_versions.v52_nodes import (
    get_v52_static_and_client_tools,
    v52_nodes_static_client_tools_repositories_beta,
)


class V52BetaClientToolsTest(unittest.TestCase):
    def test_slmicro62_minion_matches_sles160_path_and_key(self):
        beta = v52_nodes_static_client_tools_repositories_beta
        self.assertIn("sles16_client_tools", beta["slmicro62_minion"])
        self.assertNotIn("slmicro6_client_tools", beta["slmicro62_minion"])
        self.assertEqual(
            beta["slmicro62_minion"]["sles16_client_tools"],
            beta["sles160_minion"]["sles16_client_tools"],
        )
        path = beta["slmicro62_minion"]["sles16_client_tools"]
        self.assertIn("MultiLinuxManagerTools-Beta:/SLES-16:", path)
        self.assertNotIn("SL-Micro-6", path)

    def test_slmicro60_uses_sl_micro6_beta_path(self):
        beta = v52_nodes_static_client_tools_repositories_beta
        path = beta["slmicro60_minion"]["slmicro6_client_tools"]
        self.assertIn("MultiLinuxManagerTools-Beta:/SL-Micro-6:", path)

    def test_sles_beta_static_image_urls_are_prefixed_in_getter(self):
        static, _dynamic = get_v52_static_and_client_tools("sles", beta=True)
        url = static["server"]["mlm52_sles_beta_totest_images_sp7"]
        self.assertTrue(url.startswith("http://download.suse.de/ibs/SUSE:"))
        self.assertIn("SLE-15-SP7:", url)
        self.assertIn("SUSE-Multi-Linux-Manager-Server-SLE-5.2-POOL", url)

    def test_opensuse160arm_beta_dynamic_uses_sle16_aarch64(self):
        _static, dynamic = get_v52_static_and_client_tools("sles", beta=True)
        self.assertIn(
            "/SUSE_Updates_MultiLinuxManagerTools-Beta_SLE-16_aarch64/",
            dynamic["opensuse160arm_minion"],
        )


if __name__ == "__main__":
    unittest.main()
