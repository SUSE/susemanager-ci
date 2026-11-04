"""Regression tests for 5.3 beta client-tools URL semantics in v53_nodes."""

import unittest

from repository_versions.v53_nodes import (
    get_v53_static_and_client_tools,
    v53_nodes_static_client_tools_repositories_beta,
)


class V53BetaClientToolsTest(unittest.TestCase):
    def test_slmicro62_minion_matches_sles160_path_and_key(self):
        beta = v53_nodes_static_client_tools_repositories_beta
        self.assertIn("sles16_client_tools", beta["slmicro62_minion"])
        self.assertNotIn("slmicro6_client_tools", beta["slmicro62_minion"])
        self.assertEqual(
            beta["slmicro62_minion"]["sles16_client_tools"],
            beta["sles160_minion"]["sles16_client_tools"],
        )
        path = beta["slmicro62_minion"]["sles16_client_tools"]
        self.assertIn("MultiLinuxManagerTools-Beta:/SLES-16:", path)
        self.assertNotIn("SL-Micro-6", path)

    def test_v53_beta_does_not_define_slmicro60(self):
        # v53 beta intentionally only defines slmicro62_minion and sles160_minion
        # slmicro60_minion is not part of the 5.3 beta client tools structure
        beta = v53_nodes_static_client_tools_repositories_beta
        self.assertNotIn("slmicro60_minion", beta)
        # Verify the expected minions ARE defined
        self.assertIn("slmicro62_minion", beta)
        self.assertIn("sles160_minion", beta)

    def test_new_sle16_and_sap_nodes_use_the_beta_sles16_client_tools(self):
        beta = v53_nodes_static_client_tools_repositories_beta
        for node in ("sles161_minion", "slesforsap160_minion", "slesforsap161_minion"):
            self.assertEqual(
                beta[node]["sles16_client_tools"],
                beta["sles160_minion"]["sles16_client_tools"],
            )

    def test_sap15_nodes_use_the_beta_sle15_client_tools_without_ltss_plus_sap_repos(self):
        _static, dynamic = get_v53_static_and_client_tools("sles", beta=True)
        for sp in ("sp5", "sp6", "sp7"):
            sap = set(dynamic[f"slesforsap15{sp}_minion"])
            sles = set(dynamic[f"sles15{sp}_minion"])
            sap_only = {url for url in sap if "SAP" in url or "Product-HA" in url}
            self.assertTrue(sap_only)
            self.assertEqual(sap - sap_only, {url for url in sles if "LTSS" not in url})

    def test_sles_beta_static_image_urls_are_prefixed_in_getter(self):
        static, _dynamic = get_v53_static_and_client_tools("sles", beta=True)
        url = static["server"]["mlm53_sles_beta_totest_images_sp7"]
        self.assertTrue(url.startswith("http://download.suse.de/ibs/SUSE:"))
        self.assertIn("SLE-15-SP7:", url)
        self.assertIn("SUSE-Multi-Linux-Manager-Server-SLE-5.3-POOL", url)

    def test_opensuse161arm_beta_uses_static_sles16_aarch64(self):
        beta = v53_nodes_static_client_tools_repositories_beta
        self.assertIn("opensuse161arm_minion", beta)
        self.assertEqual(
            beta["opensuse161arm_minion"]["sles16_client_tools"],
            "/SLFO:/Products:/MultiLinuxManagerTools-Beta:/SLES-16:/ToTest/product/repo/Multi-Linux-ManagerTools-Beta-SLE-16-aarch64/",
        )

        static, dynamic = get_v53_static_and_client_tools("sles", beta=True)
        self.assertEqual(
            static["opensuse161arm_minion"]["sles16_client_tools"],
            "http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools-Beta:/SLES-16:/ToTest/product/repo/Multi-Linux-ManagerTools-Beta-SLE-16-aarch64/",
        )
        self.assertNotIn("opensuse161arm_minion", dynamic)


if __name__ == "__main__":
    unittest.main()
