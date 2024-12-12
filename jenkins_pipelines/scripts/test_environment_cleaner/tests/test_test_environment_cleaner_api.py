import unittest
from unittest.mock import patch, MagicMock
from test_environment_cleaner_program.test_environment_cleaner_api import ResourceManager

class TestResourceManager(unittest.TestCase):
    def setUp(self):
        self.manager_url = "localhost"
        self.resources_to_delete = {"monitoring"}
        self.product_version = "5.0"
        self.resource_manager = ResourceManager(self.manager_url, self.resources_to_delete, self.product_version)


        # Mock the ServerProxy and session key to avoid actual API calls
        self.mock_server_proxy = patch('xmlrpc.client.ServerProxy').start()
        self.mock_client = MagicMock()
        self.mock_server_proxy.return_value = self.mock_client
        self.resource_manager.client = self.mock_client
        self.resource_manager.session_key = "mock_session_key"

    def tearDown(self):
        patch.stopall()

    def test_get_session_key(self):
        # Mock the login call to return a session key
        self.mock_client.auth.login.return_value = "mock_session_key"
        self.resource_manager.get_session_key()

        self.mock_client.auth.login.assert_called_once_with("admin", "admin")
        self.assertEqual(self.resource_manager.session_key, "mock_session_key")

    def test_logout_session(self):
        self.resource_manager.logout_session()
        self.mock_client.auth.logout.assert_called_once_with("mock_session_key")

    def test_delete_users(self):
        self.mock_client.user.listUsers.return_value = [{"login": "admin"}, {"login": "test_user"}]
        self.resource_manager.delete_users()
        self.mock_client.user.delete.assert_called_once_with("mock_session_key", "test_user")

    def test_delete_activation_keys(self):
        self.mock_client.activationkey.listActivationKeys.return_value = [
            {"key": "test-key-proxy"},     # This key should not trigger a delete call
            {"key": "test-key-monitoring"}, # This key should trigger a delete call
            {"key": "test-key-sles15sp5"},  # This key should also trigger a delete call
        ]
        self.resource_manager.delete_activation_keys()
        self.mock_client.activationkey.delete.assert_any_call("mock_session_key", "test-key-monitoring")
        self.mock_client.activationkey.delete.assert_any_call("mock_session_key", "test-key-sles15sp5")
        delete_calls = self.mock_client.activationkey.delete.call_args_list
        proxy_deleted = any(call[0][1] == "test-key-proxy" for call in delete_calls)
        self.assertFalse(proxy_deleted, "delete() should not have been called with 'test-key-proxy'")
        self.assertEqual(len(delete_calls), 2)

    def test_delete_software_channels(self):
        self.mock_client.channel.listMyChannels.return_value = [
            {"label": "appstream-channel"},
            {"label": "common-channel"},
        ]
        self.mock_client.channel.software.getDetails.return_value = {
            "parent_channel_label": "parent-channel"
        }
        self.resource_manager.delete_software_channels()
        self.mock_client.channel.software.delete.assert_any_call("mock_session_key", "common-channel")

    def test_delete_systems(self):
        self.mock_client.system.listSystems.return_value = [
            {"name": "test-system-sles15sp5", "id": 1},
            {"name": "test-system-proxy", "id": 2},
            {"name": "test-system-monitoring", "id": 3}
        ]
        self.resource_manager.delete_systems()
        self.mock_client.system.deleteSystem.assert_any_call("mock_session_key", 1)
        self.mock_client.system.deleteSystem.assert_any_call("mock_session_key", 3)
        delete_calls = self.mock_client.system.deleteSystem.call_args_list
        proxy_deleted = any(call[0][1] == "test-system-proxy" for call in delete_calls)
        self.assertFalse(proxy_deleted, "delete() should not have been called with 2")
        self.assertEqual(len(delete_calls), 2)

    def test_delete_channel_repos(self):
        self.mock_client.channel.software.listUserRepos.return_value = [
            {"label": "repo1"},
            {"label": "repo2"},
        ]
        self.resource_manager.delete_channel_repos()

        self.mock_client.channel.software.removeRepo.assert_any_call("mock_session_key", "repo1")
        self.mock_client.channel.software.removeRepo.assert_any_call("mock_session_key", "repo2")

    def test_delete_software_channels_warning_for_uyuni(self):
        # Set the product_version to "uyuni" to simulate Uyuni environment
        self.resource_manager.product_version = "uyuni"

        # Patch logging to capture warning message
        with patch('logging.warning') as mock_warning:
            self.resource_manager.delete_software_channels()
            # Check if the warning message was logged
            mock_warning.assert_called_once_with("Delete only custom channels for uyuni")

    def test_delete_salt_keys(self):
        self.mock_client.saltkey.acceptedList.return_value = [
            "salt-key-monitoring",
            "salt-key-sles15sp5",
            "salt-key-proxy"
        ]
        self.resource_manager.delete_salt_keys()
        self.mock_client.saltkey.delete.assert_any_call("mock_session_key", "salt-key-sles15sp5")
        self.mock_client.saltkey.delete.assert_any_call("mock_session_key", "salt-key-monitoring")
        delete_calls = self.mock_client.saltkey.delete.call_args_list
        proxy_deleted = any(call[0][1] == "salt-key-proxy" for call in delete_calls)
        self.assertFalse(proxy_deleted, "delete() should not have been called with 'salt-key-proxy'")
        self.assertEqual(len(delete_calls), 2)

    def test_run(self):
        with patch.object(self.resource_manager, 'delete_users') as mock_delete_users, \
                patch.object(self.resource_manager, 'delete_activation_keys') as mock_delete_activation_keys, \
                patch.object(self.resource_manager, 'delete_config_projects') as mock_delete_config_projects, \
                patch.object(self.resource_manager, 'delete_software_channels') as mock_delete_software_channels, \
                patch.object(self.resource_manager, 'delete_systems') as mock_delete_systems, \
                patch.object(self.resource_manager, 'delete_channel_repos') as mock_delete_channel_repos, \
                patch.object(self.resource_manager, 'delete_salt_keys') as mock_delete_salt_keys:

            self.resource_manager.run()

            mock_delete_users.assert_called_once()
            mock_delete_activation_keys.assert_called_once()
            mock_delete_config_projects.assert_called_once()
            mock_delete_software_channels.assert_called_once()
            mock_delete_systems.assert_called_once()
            mock_delete_channel_repos.assert_called_once()
            mock_delete_salt_keys.assert_called_once()

if __name__ == '__main__':
    unittest.main()
