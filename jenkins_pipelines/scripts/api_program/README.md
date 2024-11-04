# SUSE Manager API and SSH Management Script

This Python script provides a command-line interface to manage various resources and configurations on a SUSE Manager server through the XML-RPC API and SSH commands. 
The script enables testers to perform resource cleanup, SSH-based file management, and update custom repositories remotely.

## Prerequisites

- **Python 3**: Ensure Python 3 is installed.
- **Dependencies**: Install the required packages using:

```bash
pip install argparse logging paramiko
```

## Usage

```commandline
python3 main.py --url <SUSE_Manager_URL> --mode <operation_mode> [options]
```

### Command-Line Arguments

 - `--url`: (Required) URL of the SUSE Manager XML-RPC API.
 - `--mode`: (Required) Operation mode. Choose one of the following:
    `delete_users`: Deletes user accounts.
    `delete_activation_keys`: Deletes activation keys.
    `delete_config_projects`: Deletes configuration projects.
    `delete_software_channels`: Deletes software channels.
    `delete_systems`: Deletes managed systems.
    `delete_repositories`: Deletes repositories.
    `delete_salt_keys`: Deletes Salt keys.
    `full_cleanup`: Runs a complete cleanup of selected resources.
    `delete_distributions`: Deletes distributions from the server.
    `delete_known_hosts`: Deletes known SSH hosts in server.
    `update_custom_repositories`: Updates custom repositories in controller.
 - `--default-resources-to-delete`: Optional list of resources (proxy, monitoring-server, retail) to enforce deletion during API cleanup operations.
 - `--product_version`: SUSE Manager version (5.0 or 4.3). Used for handling different paths in specific operations.
