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
    'delete_software_channels', 'delete_systems', 'delete_system', 'delete_repositories',
    'full_cleanup', 'delete_salt_keys', 'delete_known_hosts',
    'update_custom_repositories', 'delete_distributions', 'delete_system_groups',
    'delete_images', 'delete_image_profiles', 'update_terminal_mac_addresses'
]

def main():
    parser = argparse.ArgumentParser(description="Manage SUSE Manager API actions.")
    parser.add_argument("--url", required=True, help="The URL of the SUSE Manager XML-RPC API.")
    parser.add_argument("--mode", required=True, choices=MODES, help="The mode of operation.")
    parser.add_argument("--default-resources-to-delete", type=str, nargs='*',
                        choices=['proxy', 'monitoring-server', 'build', 'terminal'],
                        default=[], help='List of default modules to force deletion')
    parser.add_argument("--controller_url",required=False, help="The controller URL.")
    parser.add_argument("--hypervisor_url",required=False, help="The terminal hypervisor URL.")
    parser.add_argument("--system-to-delete",required=False, help="System name to delete")

    args = parser.parse_args()
    manager_url = args.url
    default_resources_to_delete = [
        item.replace("monitoring-server", "monitoring") if item == "monitoring-server" else item
        for item in args.default_resources_to_delete
    ]

    resource_manager = ResourceManager(manager_url, default_resources_to_delete)
    product_version = resource_manager.get_product_version()
    # API part
    if args.mode in ["delete_users", "delete_activation_keys", "delete_config_projects",
                     "delete_software_channels", "delete_systems", "delete_repositories",
                     "full_cleanup", "delete_salt_keys", "delete_system_groups", "delete_images",
                     "delete_image_profiles", "delete_system"]:
        resource_manager.get_session_key()
        mode_actions = {
            "delete_users": resource_manager.delete_users,
            "delete_activation_keys": resource_manager.delete_activation_keys,
            "delete_config_projects": resource_manager.delete_config_projects,
            "delete_software_channels": resource_manager.delete_software_channels,
            "delete_systems": resource_manager.delete_systems,
            "delete_system": resource_manager.delete_system(args.system_to_delete),
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
    elif args.mode in ["update_terminal_mac_addresses"]:
        ssh_controller_session = SSHClientManager(url=args.controller_url, password= "linux")
        ssh_hypervisor_session = SSHClientManager(url=args.hypervisor_url,ssh_key_path="/home/jenkins/.ssh/id_rsa")
        virsh_output = ssh_hypervisor_session.run_command(f"virsh list | grep terminal | grep {''.join(product_version.split('.')[:2])} | awk '{{print $2}}'")
        terminal_names = virsh_output.strip().split("\n") if virsh_output.strip() else []
        logger.debug(f"Terminal list: {terminal_names}")
        for terminal_name in terminal_names:
            logger.debug(f"Updating the mac address to controller for {terminal_name.replace('sles','sle').upper().split('-')[-2]}")
            macaddress = ssh_hypervisor_session.run_command(f"virsh domiflist {terminal_name} | grep -v 'Interface' | awk '{{print $5}}'")
            ssh_controller_session.run_command(
                f"sed -i 's|^export {terminal_name.replace('sles', 'sle').upper().split('-')[-2]}_TERMINAL_MAC=\".*\"|export {terminal_name.replace('sles', 'sle').upper().split('-')[-2]}_TERMINAL_MAC=\"{macaddress.upper()}\"|' /root/.bashrc"
            )
    else:
        ssh_manager = SSHClientManager(url=manager_url, password= "linux", product_version=product_version)
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
