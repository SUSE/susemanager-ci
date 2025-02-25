#!/usr/bin/python3.11
import argparse
import logging
from test_environment_cleaner_api import ResourceManager
from test_environment_cleaner_ssh import SSHClientManager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Define the available modes
MODES = [
    'delete_users', 'delete_activation_keys', 'delete_config_projects',
    'delete_software_channels', 'delete_systems', 'delete_repositories',
    'full_cleanup', 'delete_salt_keys', 'delete_known_hosts',
    'update_custom_repositories', 'delete_distributions', 'delete_system_groups',
    'delete_images', 'delete_image_profiles'
]

def main():
    parser = argparse.ArgumentParser(description="Manage SUSE Manager API actions.")
    parser.add_argument("--url", required=True, help="The URL of the SUSE Manager XML-RPC API.")
    parser.add_argument("--mode", required=True, choices=MODES, help="The mode of operation.")
    parser.add_argument("--default-resources-to-delete", type=str, nargs='*',
                        choices=['proxy', 'monitoring-server', 'build', 'terminal'],
                        default=[], help='List of default modules to force deletion')

    args = parser.parse_args()
    manager_url = args.url
    default_resources_to_delete = [
        item.replace("monitoring-server", "monitoring") if item == "monitoring-server" else item
        for item in args.default_resources_to_delete
    ]

    resource_manager = ResourceManager(manager_url, default_resources_to_delete)
    # API part
    if args.mode in ["delete_users", "delete_activation_keys", "delete_config_projects",
                     "delete_software_channels", "delete_systems", "delete_repositories",
                     "full_cleanup", "delete_salt_keys", "delete_system_groups", "delete_images"
                     "delete_image_profiles"]:
        resource_manager.get_session_key()
        mode_actions = {
            "delete_users": resource_manager.delete_users,
            "delete_activation_keys": resource_manager.delete_activation_keys,
            "delete_config_projects": resource_manager.delete_config_projects,
            "delete_software_channels": resource_manager.delete_software_channels,
            "delete_systems": resource_manager.delete_systems,
            "delete_repositories": resource_manager.delete_channel_repos,
            "delete_salt_keys": resource_manager.delete_salt_keys,
            "delete_system_groups": resource_manager.delete_system_groups,
            "delete_images": resource_manager.delete_images,
            "delete_image_profiles": resource_manager.delete_image_profiles,
            "full_cleanup": resource_manager.run,
        }
        try:
            action = mode_actions.get(args.mode)
            if action:
                action()
            else:
                logger.error(f"Mode '{args.mode}' is not recognized.")
        finally:
            resource_manager.logout_session()

    # Server commands part
    else:
        product_version = resource_manager.get_product_version()
        ssh_manager = SSHClientManager(url=manager_url, product_version=product_version)
        ssh_actions = {
            "delete_known_hosts": ssh_manager.delete_known_hosts,
            "delete_distributions": ssh_manager.delete_distributions,
            "update_custom_repositories": ssh_manager.update_custom_repositories,
        }
        action = ssh_actions.get(args.mode)
        if action:
            action()
        else:
            logger.error(f"Mode '{args.mode}' is not recognized.")


if __name__ == "__main__":
    main()
