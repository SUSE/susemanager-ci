import unittest
from unittest.mock import patch
import sys
from io import StringIO
import os

# Add the root directory of the project to the sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))
from test_environment_cleaner_program.TestEnvironmentCleaner import main

class TestMainProgram(unittest.TestCase):
    def setUp(self):
        self.product_version = "5.0"

    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.ResourceManager")
    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.SSHClientManager")
    def test_delete_users_mode(self, MockSSHClientManager, MockResourceManager):
        test_args = ["test_environment_cleaner_program.TestEnvironmentCleaner", "--url", "http://test-url.com", "--mode", "delete_users"]
        with patch.object(sys, 'argv', test_args):
            mock_resource_manager = MockResourceManager.return_value
            mock_resource_manager.get_session_key.return_value = "session_key"

            main()

            MockResourceManager.assert_called_once_with("http://test-url.com", [])
            mock_resource_manager.get_session_key.assert_called_once()
            mock_resource_manager.delete_users.assert_called_once()
            mock_resource_manager.logout_session.assert_called_once()

    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.ResourceManager")
    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.SSHClientManager")
    def test_delete_known_hosts_mode(self, MockSSHClientManager, MockResourceManager):
        test_args = ["test_environment_cleaner_program.TestEnvironmentCleaner", "--url", "http://test-url.com", "--mode", "delete_known_hosts"]
        with patch.object(sys, 'argv', test_args):
            # Configure the ResourceManager mock
            mock_resource_manager = MockResourceManager.return_value
            mock_resource_manager.get_product_version.return_value = "5.0"

            mock_ssh_manager = MockSSHClientManager.return_value

            main()

            MockSSHClientManager.assert_called_once_with(url="http://test-url.com", password='linux', product_version="5.0")
            mock_ssh_manager.delete_known_hosts.assert_called_once()

    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.ResourceManager")
    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.SSHClientManager")
    def test_invalid_mode(self, MockSSHClientManager, MockResourceManager):
        test_args = ["test_environment_cleaner_program.TestEnvironmentCleaner", "--url", "http://test-url.com", "--mode", "invalid"]
        with patch.object(sys, 'argv', test_args):
            with patch("sys.stderr", new=StringIO()) as fake_err:
                with self.assertRaises(SystemExit):
                    main()

                # Assert the error message is in the captured stderr
                expected_error_message = (
                    "usage: test_environment_cleaner_program.TestEnvironmentCleaner [-h] --url URL --mode "
                    "{delete_users,delete_activation_keys,delete_config_projects,delete_software_channels,"
                    "delete_systems,delete_repositories,full_cleanup,delete_salt_keys,delete_known_hosts,update_custom_repositories,delete_distributions,delete_system_groups,delete_images,delete_image_profiles,update_terminal_mac_addresses}"
                    " [--default-resources-to-delete [{proxy,monitoring-server,build,terminal} ...]] [--controller_url CONTROLLER_URL] [--hypervisor_url HYPERVISOR_URL] "
                    "test_environment_cleaner_program.TestEnvironmentCleaner: error: argument --mode: invalid choice: 'invalid' (choose from 'delete_users',"
                    " 'delete_activation_keys', 'delete_config_projects', 'delete_software_channels', 'delete_systems',"
                    " 'delete_repositories', 'full_cleanup', 'delete_salt_keys', 'delete_known_hosts', 'update_custom_repositories',"
                    " 'delete_distributions', 'delete_system_groups', 'delete_images', 'delete_image_profiles', 'update_terminal_mac_addresses')"
                )
                cleaned_error = " ".join(fake_err.getvalue().split())
                self.assertIn(expected_error_message, cleaned_error)

    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.ResourceManager")
    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.SSHClientManager")
    def test_update_custom_repositories_mode(self, MockSSHClientManager, MockResourceManager):
        test_args = ["test_environment_cleaner_program.TestEnvironmentCleaner", "--url", "http://test-url.com", "--mode", "update_custom_repositories"]
        with patch.object(sys, 'argv', test_args):
            mock_ssh_manager = MockSSHClientManager.return_value

            main()

            mock_ssh_manager.update_custom_repositories.assert_called_once()

if __name__ == "__main__":
    unittest.main()
