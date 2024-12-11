import unittest
from unittest.mock import patch
import sys
from io import StringIO
import os

# Add the root directory of the project to the sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))
from test_environment_cleaner_program.TestEnvironmentCleaner import main  # Ensure the import is correct

class TestMainProgram(unittest.TestCase):

    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.ResourceManager")
    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.SSHClientManager")
    def test_delete_users_mode(self, MockSSHClientManager, MockResourceManager):
        # Mock the arguments
        test_args = ["test_environment_cleaner_program.TestEnvironmentCleaner", "--url", "http://test-url.com", "--mode", "delete_users", "--product_version", "5.0"]
        with patch.object(sys, 'argv', test_args):
            # Mock ResourceManager and its methods
            mock_resource_manager = MockResourceManager.return_value
            mock_resource_manager.get_session_key.return_value = "session_key"

            # Run the main program
            main()

            # Check ResourceManager was initialized and called
            MockResourceManager.assert_called_once_with("http://test-url.com", [],"5.0")
            mock_resource_manager.get_session_key.assert_called_once()
            mock_resource_manager.delete_users.assert_called_once()
            mock_resource_manager.logout_session.assert_called_once()

    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.ResourceManager")
    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.SSHClientManager")
    def test_delete_known_hosts_mode(self, MockSSHClientManager, MockResourceManager):
        test_args = ["test_environment_cleaner_program.TestEnvironmentCleaner", "--url", "http://test-url.com", "--mode", "delete_known_hosts", "--product_version", "5.0"]
        with patch.object(sys, 'argv', test_args):
            # Mock SSHClientManager and its methods
            mock_ssh_manager = MockSSHClientManager.return_value
            mock_ssh_manager.run_command.return_value = "command_output"

            # Run the main program
            main()

            # Check SSHClientManager was initialized and called
            MockSSHClientManager.assert_called_once_with(url="http://test-url.com")
            mock_ssh_manager.run_command.assert_any_call("rm /var/lib/containers/storage/volumes/var-salt/_data/.ssh/known_hosts")
            mock_ssh_manager.close.assert_called_once()

    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.ResourceManager")
    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.SSHClientManager")
    def test_invalid_mode(self, MockSSHClientManager, MockResourceManager):
        # Define the test argument with an invalid mode
        test_args = ["suse_manager_cleaner_program.TestEnvironmentCleaner", "--url", "http://test-url.com", "--mode", "false", "--product_version", "5.0"]

        # Patch sys.argv with the test arguments
        with patch.object(sys, 'argv', test_args):
            # Capture the output to stderr and expect a SystemExit
            with patch("sys.stderr", new=StringIO()) as fake_err:
                with self.assertRaises(SystemExit):  # Expecting a SystemExit
                    main()

                # Assert the error message is in the captured stderr
                expected_error_message = (
                    "usage: suse_manager_cleaner_program.TestEnvironmentCleaner [-h] --url URL --mode "
                    "{delete_users,delete_activation_keys,delete_config_projects,delete_software_channels,"
                    "delete_systems,delete_repositories,full_cleanup,delete_salt_keys,delete_known_hosts,update_custom_repositories,delete_distributions}"
                    " [--default-resources-to-delete [{proxy,monitoring-server,retail} ...]] --product_version {head,5.1,5.0,4.3,uyuni} "
                    "suse_manager_cleaner_program.TestEnvironmentCleaner: error: argument --mode: invalid choice: 'false' (choose from 'delete_users',"
                    " 'delete_activation_keys', 'delete_config_projects', 'delete_software_channels', 'delete_systems',"
                    " 'delete_repositories', 'full_cleanup', 'delete_salt_keys', 'delete_known_hosts', 'update_custom_repositories',"
                    " 'delete_distributions')"
                )
                cleaned_error = " ".join(fake_err.getvalue().split())
                self.assertIn(expected_error_message, cleaned_error)

    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.ResourceManager")
    @patch("test_environment_cleaner_program.TestEnvironmentCleaner.SSHClientManager")
    def test_update_custom_repositories_mode(self, MockSSHClientManager, MockResourceManager):
        test_args = ["test_environment_cleaner_program.TestEnvironmentCleaner", "--url", "http://test-url.com", "--mode", "update_custom_repositories", "--product_version", "5.0"]
        with patch.object(sys, 'argv', test_args):
            # Mock SSHClientManager and its methods
            mock_ssh_manager = MockSSHClientManager.return_value

            # Run the main program
            main()

            # Check copy_file is called with the correct arguments
            mock_ssh_manager.copy_file.assert_called_once_with("./custom_repositories.json", "/root/spacewalk/testsuite/features/upload_files/custom_repositories.json")
            mock_ssh_manager.close.assert_called_once()

if __name__ == "__main__":
    unittest.main()
