#!/usr/bin/python3
import argparse
import logging
from suse_manager_api import ResourceManager
from suse_manager_ssh import run_ssh_command, copy_file_over_ssh

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Manage SUSE Manager API actions.")
    parser.add_argument("--url", required=True, help="The URL of the SUSE Manager XML-RPC API.")
    parser.add_argument("--mode", choices=["delete_users", "delete_activation_keys", "delete_config_projects", "delete_software_channels", "delete_systems", "delete_repositories", "full_cleanup", "delete_salt_keys", "delete_known_hosts", "update_custom_repositories"], help="The mode of operation.")
    parser.add_argument('--tf-resources-to-delete', type=str, nargs='*', choices=['proxy', 'monitoring-server', 'retail'], default=[],
                         help='List of default modules to force deletion')

    args = parser.parse_args()

    manager_url = args.url

    if args.mode in ["delete_users", "delete_activation_keys", "delete_config_projects", "delete_software_channels", "delete_systems", "delete_repositories", "full_cleanup", "delete_salt_keys"]:
        resource_manager = ResourceManager(manager_url, args.tf_resources_to_delete)
        resource_manager.get_session_key()

        if args.mode == "delete_users":
            resource_manager.delete_users()
        elif args.mode == "delete_activation_keys":
            resource_manager.delete_activation_keys()
        elif args.mode == "delete_config_projects":
            resource_manager.delete_config_projects()
        elif args.mode == "delete_software_channels":
            resource_manager.delete_software_channels()
        elif args.mode == "delete_systems":
            resource_manager.delete_systems()
        elif args.mode == "delete_repositories":
            resource_manager.delete_channel_repos()
        elif args.mode == "delete_salt_keys":
            resource_manager.delete_salt_keys()
        elif args.mode == "full_cleanup":
            resource_manager.run()

        resource_manager.logout_session()

    elif args.mode == "delete_known_hosts":
        run_ssh_command(manager_url, "rm /var/lib/salt/.ssh/known_hosts")
        logger.info("Deleted known_hosts file on server")

    elif args.mode == "delete_distributions":
        run_ssh_command(manager_url, "rm -rf /var/lib/containers/storage/volumes/srv-www/_data/distributions/*")
        logger.info("Deleted distributions directory on 5.0 server")

    elif args.mode == "update_custom_repositories":
        copy_file_over_ssh(manager_url, "", "/root/spacewalk/testsuite/features/upload_files/custom_repositories.json")
