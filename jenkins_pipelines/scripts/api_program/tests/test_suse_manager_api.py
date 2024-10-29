import unittest
from unittest.mock import patch, MagicMock
from api_program.suse_manager_api import ResourceManager

class TestResourceManager(unittest.TestCase):
    def setUp(self):
        self.manager_url = "localhost"
        self.resources_to_delete = {"proxy", "monitoring"}
        self.resource_manager = ResourceManager(self.manager_url, self.resources_to_delete)

        # Mock the ServerProxy and session key to avoid actual API calls
        self.mock_server_proxy = patch('xmlrpc.client.ServerProxy').start()
        self.mock_client = MagicMock()
        self.mock_server_proxy.return_value = self.mock_client
        self.resource_manager.client = self.mock_client
        self.resource_manager.session_key = "mock_session_key"

    def tearDown(self):
        patch.stopall()

    def test_get_session_key(self):
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
            {"key": "test-key-proxy"},
            {"key": "test-key"},
        ]
        self.resource_manager.delete_activation_keys()

        # Check that delete was called with both keys
        self.mock_client.activationkey.delete.assert_any_call("mock_session_key", "test-key-proxy")
        self.mock_client.activationkey.delete.assert_any_call("mock_session_key", "test-key")


    def test_delete_config_projects(self):
        self.mock_client.contentmanagement.listProjects.return_value = [{"label": "test_project"}]
        self.resource_manager.delete_config_projects()
        self.mock_client.contentmanagement.removeProject.assert_called_once_with("mock_session_key", "test_project")

    def test_delete_software_channels(self):
        self.mock_client.channel.listMyChannels.return_value = [
            {"label": "appstream-channel"},
            {"label": "common-channel"},
        ]
        self.mock_client.channel.software.getDetails.return_value = {"parent_channel_label": "parent-channel"}

        self.resource_manager.delete_software_channels()

        # Checking if delete called for "common-channel" which is not protected
        self.mock_client.channel.software.delete.assert_any_call("mock_session_key", "common-channel")

    def test_delete_systems(self):
        self.mock_client.system.listSystems.return_value = [
            {"name": "test-system-monitoring", "id": 1},
            {"name": "test-system", "id": 2},
        ]
        self.resource_manager.delete_systems()

        # Check that deleteSystem was called with both IDs
        self.mock_client.system.deleteSystem.assert_any_call("mock_session_key", 1)
        self.mock_client.system.deleteSystem.assert_any_call("mock_session_key", 2)

    def test_delete_channel_repos(self):
        self.mock_client.channel.software.listUserRepos.return_value = [{"label": "repo1"}, {"label": "repo2"}]
        self.resource_manager.delete_channel_repos()
        self.mock_client.channel.software.removeRepo.assert_any_call("mock_session_key", "repo1")
        self.mock_client.channel.software.removeRepo.assert_any_call("mock_session_key", "repo2")

    def test_delete_salt_keys(self):
        self.mock_client.saltkey.acceptedList.return_value = ["salt-key-monitoring", "salt-key-other"]
        self.resource_manager.delete_salt_keys()

        # Check that delete was called with both keys
        self.mock_client.saltkey.delete.assert_any_call("mock_session_key", "salt-key-monitoring")
        self.mock_client.saltkey.delete.assert_any_call("mock_session_key", "salt-key-other")


    @patch.object(ResourceManager, 'get_session_key')
    @patch.object(ResourceManager, 'logout_session')
    def test_run(self, mock_logout_session, mock_get_session_key):
        # Mock all deletion methods to avoid unwanted deletions during the test
        with patch.object(self.resource_manager, 'delete_users') as mock_delete_users, \
                patch.object(self.resource_manager, 'delete_activation_keys') as mock_delete_activation_keys, \
                patch.object(self.resource_manager, 'delete_config_projects') as mock_delete_config_projects, \
                patch.object(self.resource_manager, 'delete_software_channels') as mock_delete_software_channels, \
                patch.object(self.resource_manager, 'delete_systems') as mock_delete_systems, \
                patch.object(self.resource_manager, 'delete_channel_repos') as mock_delete_channel_repos, \
                patch.object(self.resource_manager, 'delete_salt_keys') as mock_delete_salt_keys:

            # Run the full cleanup
            self.resource_manager.run()

            # Verify that each method was called once
            mock_get_session_key.assert_called_once()
            mock_delete_users.assert_called_once()
            mock_delete_activation_keys.assert_called_once()
            mock_delete_config_projects.assert_called_once()
            mock_delete_software_channels.assert_called_once()
            mock_delete_systems.assert_called_once()
            mock_delete_channel_repos.assert_called_once()
            mock_delete_salt_keys.assert_called_once()
            mock_logout_session.assert_called_once()

if __name__ == '__main__':
    unittest.main()
