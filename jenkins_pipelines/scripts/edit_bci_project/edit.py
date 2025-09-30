#!/usr/bin/python3

# Copyright (c) 2025 SUSE LLC
#
# This software is licensed to you under the GNU General Public License,
# version 2 (GPLv2). There is NO WARRANTY for this software, express or
# implied, including the implied warranties of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
# along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

import argparse
import subprocess
import os
import xml.etree.ElementTree as ET
import tempfile
import re
import requests
from bs4 import BeautifulSoup
import logging
import sys


def run_osc_command(command, input_data=None):
    """
    A helper function to run osc commands and handle their output and errors.
    It returns the stdout of the command.
    """
    logging.info(f"Running command: {' '.join(command)}")
    try:
        # Use subprocess.PIPE to capture stdout and stderr
        result = subprocess.run(
            command,
            input=input_data,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            encoding="utf-8",
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        # Log the command that failed and its stderr output for debugging
        logging.error(f"Failed to execute command: {' '.join(command)}")
        logging.error(f"STDERR:\n{e.stderr.strip()}")
        exit(1)


def print_registry(container_project):
    """
    Finds and print the first file ending with '*.registry.txt' from a remote directory.
    """
    base_url = f"http://download.suse.de/ibs/{container_project.replace(':', ':/')}/containerfile/"
    logging.info(f"Searching for registry file at: {base_url}")

    try:
        response = requests.get(base_url)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')

        for link in soup.find_all('a'):
            filename = link.get('href')
            if filename and filename.endswith('.registry.txt'):
                registry_url = f"{base_url}{filename}"
                logging.info(f"Found registry file: {filename}")
                file_response = requests.get(registry_url)
                file_response.raise_for_status()
                # The final output is printed to stdout, logs go to stderr
                print(file_response.text.splitlines()[1].split().pop())
                return  # Exit once the first file is found and downloaded

        # This part is reached if the loop completes without finding the file
        logging.error(f"Could not find a '.registry.txt' file at the specified URL.")
        exit(1)

    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to access build results URL: {e}")
        exit(1)


def main():
    """
    Main function to parse arguments and run the update logic.
    """
    # Configure logging to print to stderr
    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s', stream=sys.stderr)

    parser = argparse.ArgumentParser(description="Automate editing OBS project metadata and configuration.")
    parser.add_argument("--container-project", required=True,
                        help="The name of the OBS project (e.g., home:oscar-barrios:SLE_Testing).")
    parser.add_argument("--api-url", default="https://api.suse.de",
                        help="The OBS API URL to use (e.g., https://api.suse.de).")
    parser.add_argument("--prefer",
                        help="The value for the 'Prefer' rule in project config (e.g., container:suse-manager-5.0-init-5.0.5).")
    parser.add_argument("--mi-project", help="The project name of the MI to validate (e.g., SUSE:Maintenance:12345).")
    parser.add_argument("--mi-repo-name",
                        help="The repository name including the packages to validate (e.g., SUSE_Updates_SLE-Module-Basesystem_15-SP6_x86_64).")
    args = parser.parse_args()

    # --- Edit Project Configuration (prjconf) ---
    if args.prefer:
        # 1. Get current project configuration using `osc meta prjconf`
        prjconf_cmd = ["osc", "-A", args.api_url, "meta", "prjconf", args.container_project]
        current_prjconf = run_osc_command(prjconf_cmd)

        # 2. Modify prjconf content to set the 'Prefer' rule
        prefer_line = f"Prefer: {args.prefer}"
        lines = current_prjconf.splitlines()
        new_lines = []
        found_prefer = False
        for line in lines:
            if line.strip().startswith("Prefer:"):
                # Replace the existing line
                new_lines.append(prefer_line)
                found_prefer = True
            else:
                new_lines.append(line)
        if not found_prefer:
            # Add the line if it doesn't exist
            new_lines.append(prefer_line)

        modified_prjconf = "\n".join(new_lines) + "\n"

        # 3. Write modified prjconf to a temporary file and upload it
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp_file:
            tmp_file.write(modified_prjconf)
            tmp_file_path = tmp_file.name

        upload_cmd = ["osc", "-A", args.api_url, "meta", "prjconf", args.container_project, "-F", tmp_file_path]
        run_osc_command(upload_cmd)
        os.remove(tmp_file_path)
        logging.info(f"Successfully updated project configuration for '{args.container_project}'.")

    # --- Edit Project Metadata (meta) ---
    if args.mi_project and args.mi_repo_name:
        # 1. Get current project metadata using `osc meta prj`
        meta_cmd = ["osc", "-A", args.api_url, "meta", "prj", args.container_project]
        current_meta_xml = run_osc_command(meta_cmd)

        # 2. Parse and modify the XML using ElementTree
        try:
            root = ET.fromstring(current_meta_xml)
            containerfile_repo = root.find(".//repository[@name='containerfile']")
            if containerfile_repo is None:
                raise ValueError("Could not find repository with name='containerfile' in the metadata.")

            # Find the path to modify by its original project name
            path_to_modify = None
            for path_elem in containerfile_repo.findall("./path"):
                # Use a regular expression to match projects like "SUSE:Maintenance:12345"
                if re.match(r'SUSE:Maintenance:\d+', path_elem.get('project')):
                    path_to_modify = path_elem
                    break

            if path_to_modify is None:
                raise ValueError("Could not find a matching SUSE:Maintenance path to modify in the metadata.")

            # Update the 'project' and 'repository' attributes
            path_to_modify.set('project', args.mi_project)
            path_to_modify.set('repository', args.mi_repo_name)

            # 3. Write modified XML to a temporary file and upload it
            modified_meta_xml = ET.tostring(root, encoding='unicode')

            with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp_file:
                tmp_file.write(modified_meta_xml)
                tmp_file_path = tmp_file.name

            upload_cmd = ["osc", "-A", args.api_url, "meta", "prj", args.container_project, "-F", tmp_file_path]
            run_osc_command(upload_cmd)
            os.remove(tmp_file_path)
            logging.info(f"Successfully updated project metadata for '{args.container_project}'.")
            print_registry(args.container_project)

        except ET.ParseError:
            logging.error("Failed to parse the project metadata XML. It might be malformed.")
            exit(1)
        except ValueError as e:
            # The custom ValueError messages are now logged as errors
            logging.error(e)
            exit(1)


if __name__ == "__main__":
    main()