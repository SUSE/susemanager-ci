#!/usr/bin/python3
import argparse
from suse_manager_api import get_session_key, logout_session, delete_users, delete_activation_keys, delete_config_projects, delete_software_channels, delete_systems, delete_channel_repos, delete_salt_keys
from suse_manager_ssh import run_ssh_command
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Manage SUSE Manager API actions.")
    parser.add_argument("url", help="The URL of the SUSE Manager XML-RPC API.")
    parser.add_argument("mode", choices=["delete_users", "delete_activation_keys", "delete_config_projects", "delete_software_channels", "delete_systems", "delete_repositories","full_cleanup", "delete_salt_keys", "delete_known_hosts"], help="The mode of operation.")

    args = parser.parse_args()

    manager_url = args.url

    session_key, client = get_session_key(manager_url)

    try:
        if args.mode == "delete_users":
            delete_users(client, session_key)
        elif args.mode == "delete_activation_keys":
            delete_activation_keys(client, session_key)
        elif args.mode == "delete_config_channels":
            delete_config_channels(client, session_key)
        elif args.mode == "delete_software_channels":
            delete_software_channels(client, session_key)
        elif args.mode == "delete_systems":
            delete_systems(client, session_key)
        elif args.mode == "delete_repositories":
            delete_channel_repos(client, session_key)
        elif args.mode == "delete_salt_keys":
            delete_salt_keys(client, session_key)
        elif args.mode == "delete_known_hosts":
            run_ssh_command(manager_url, "rm /var/lib/salt/.ssh/known_hosts")
        elif args.mode == "update_custom_repositories":
            copy_file_over_ssh(manager_url, "","/root/spacewalk/testsuite/features/upload_files/custom_repositories.json")
        elif args.mode == "delete_config_projects":
            delete_config_projects(client, session_key)
        elif args.mode == "full_cleanup":
            delete_systems(client, session_key)
            delete_config_projects(client, session_key)
            delete_software_channels(client, session_key)
            delete_activation_keys(client, session_key)
            delete_users(client, session_key)
            delete_channel_repos(client, session_key)
            delete_salt_keys(client,session_key)
            run_ssh_command(manager_url, "rm /var/lib/salt/.ssh/known_hosts")
            logger.info("Delete known_hosts file on server")
    finally:
        logout_session(client, session_key)