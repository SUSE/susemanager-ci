import unittest
import xmlrpc.client
from unittest.mock import MagicMock
from test_environment_cleaner_program.test_environment_cleaner_api import ResourceManager


class TestStaticChannelCleanup(unittest.TestCase):
    def setUp(self):
        self.rm = ResourceManager("localhost", set())
        self.rm.client = MagicMock()
        self.rm.session_key = "k"

    def test_channel_with_custom_name_but_plain_label_is_deleted(self):
        sw = self.rm.client.channel.software
        self.rm.client.channel.listMyChannels.return_value = [
            {"label": "rocky-8-iso", "name": "Custom Channel for Rocky 8 DVD"},
            {"label": "sles15-sp7-updates", "name": "SLES15-SP7-Updates"},
        ]
        sw.getDetails.return_value = {"parent_channel_label": "rockylinux-8-x86_64"}
        self.rm.delete_software_channels()
        sw.delete.assert_called_once_with("k", "rocky-8-iso")

    def test_repo_removal_continues_after_fault(self):
        sw = self.rm.client.channel.software
        sw.listUserRepos.return_value = [{"label": "a"}, {"label": "b"}]
        sw.removeRepo.side_effect = [xmlrpc.client.Fault(1, "in use"), 1]
        self.rm.delete_channel_repos()
        self.assertEqual(sw.removeRepo.call_count, 2)


if __name__ == "__main__":
    unittest.main()
