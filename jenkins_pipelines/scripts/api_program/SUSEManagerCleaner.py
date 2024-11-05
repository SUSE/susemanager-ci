#!/usr/bin/python3
import argparse
import logging
from suse_manager_api import ResourceManager
from suse_manager_ssh import SSHClientManager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Manage SUSE Manager API actions.")
    parser.add_argument("--url", required=True, help="The URL of the SUSE Manager XML-RPC API.")
    parser.add_argument("--mode", choices=["delete_users", "delete_activation_keys", "delete_config_projects", "delete_software_channels", "delete_systems", "delete_repositories", "full_cleanup", "delete_salt_keys", "delete_known_hosts", "update_custom_repositories", "delete_distributions"], help="The mode of operation.")
    parser.add_argument("--default-resources-to-delete", type=str, nargs='*', choices=['proxy', 'monitoring-server', 'retail'], default=[], help='List of default modules to force deletion')
    parser.add_argument("--product_version", type=str, choices=['5.0', '4.3'])

    args = parser.parse_args()
    manager_url = args.url

   # API part
    if args.mode in ["delete_users", "delete_activation_keys", "delete_config_projects", "delete_software_channels", "delete_systems", "delete_repositories", "full_cleanup", "delete_salt_keys"]:
        resource_manager = ResourceManager(manager_url, args.default_resources_to_delete)
        resource_manager.get_session_key()
        # Mapping args.mode to the corresponding ResourceManager method
        mode_actions = {
            "delete_users": resource_manager.delete_users,
            "delete_activation_keys": resource_manager.delete_activation_keys,
            "delete_config_projects": resource_manager.delete_config_projects,
            "delete_software_channels": resource_manager.delete_software_channels,
            "delete_systems": resource_manager.delete_systems,
            "delete_repositories": resource_manager.delete_channel_repos,
            "delete_salt_keys": resource_manager.delete_salt_keys,
            "full_cleanup": resource_manager.run,
        }
        try:
            # Execute the method based on the mode
            action = mode_actions.get(args.mode)
            if action:
                action()
            else:
                logger.error(f"Mode '{args.mode}' is not recognized.")
        finally:
            resource_manager.logout_session()

    # Server commands part
    else:
        # Initialize SSH Manager
        ssh_manager = SSHClientManager(url=manager_url)
        try:
            if args.mode == "delete_known_hosts":
                if args.product_version == "4.3":
                    ssh_manager.run_command("rm /var/lib/salt/.ssh/known_hosts")
                elif args.product_version == "5.0":
                    result = ssh_manager.run_command("ls -la /var/lib/containers/storage/volumes/var-salt/_data/.ssh/known_hosts")
                    logger.info(f"Files in salt ssh before cleanup : {result}")
                    ssh_manager.run_command("rm /var/lib/containers/storage/volumes/var-salt/_data/.ssh/known_hosts")
                    logger.info(f"Files in salt ssh after cleanup : {result}")
                logger.info("Deleted known_hosts file on server")

            elif args.mode == "delete_distributions":
                if args.product_version == "4.3":
                    logger.warning("Distribution delete to do 4.3")
                elif args.product_version == "5.0":
                    ssh_manager.run_command("rm -rf /var/lib/containers/storage/volumes/srv-www/_data/distributions/*")
                    ssh_manager.run_command("rm -rf /var/lib/containers/storage/volumes/srv-www/_data/htdocs/pub/*iso")
                logger.info("Deleted distributions directory on server")

            elif args.mode == "update_custom_repositories":
                ssh_manager.copy_file("", "/root/spacewalk/testsuite/features/upload_files/custom_repositories.json")
        finally:
            # Ensure the connection is closed
            ssh_manager.close()
