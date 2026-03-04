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
import time


def run_osc_command(command, input_data=None):
    """
    A helper function to run osc commands from a neutral directory.
    It returns the stdout of the command.
    """
    logging.info(f"Running command: {' '.join(command)}")

    try:
        result = subprocess.run(
            command,
            input=input_data,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            encoding="utf-8",
            check=True,
            cwd=tempfile.gettempdir()
        )
        return result.stdout

    except subprocess.CalledProcessError as e:
        logging.error(f"STDOUT:\n{e.stdout.strip()}\nSTDERR:\n{e.stderr.strip()}")
        sys.exit(1)


def wait_for_build_completion(api_url, project, repository="containerfile", timeout_minutes=90):
    """
    Polls the OBS project until all packages in the specified repository
    reach a 'succeeded' (or ignored) state.

    Includes an initial safety sleep to ensure the scheduler has time to
    acknowledge the 'rebuild' command.
    """
    # --- SAFETY SLEEP ---
    # Since we explicitly call 'osc rebuild' now, we wait 30 seconds
    # for the backend to transition from 'succeeded' to 'scheduled' or 'building'.
    logging.info(f"Waiting 30 seconds for the IBS/OBS scheduler to process the rebuild request...")
    time.sleep(30)

    logging.info(f"Starting to poll build results in project '{project}', repository '{repository}'...")

    start_time = time.time()
    timeout_seconds = timeout_minutes * 60
    cmd = ["osc", "-A", api_url, "results", project, "-r", repository, "--xml"]

    success_states = {'succeeded', 'excluded', 'disabled'}
    failure_states = {'failed', 'broken', 'unresolvable'}

    while True:
        # Check for timeout
        elapsed_time = time.time() - start_time
        if elapsed_time > timeout_seconds:
            logging.error(f"Timeout reached: Build did not complete within {timeout_minutes} minutes.")
            sys.exit(1)

        try:
            xml_output = run_osc_command(cmd)
            root = ET.fromstring(xml_output)

            # Extract all 'code' attributes from <status> tags
            statuses = [status.get('code') for status in root.findall(".//status")]

            if not statuses:
                logging.info("No package status found yet. Waiting...")
                time.sleep(15)
                continue

            # Check for failures
            failed_packages = [s for s in statuses if s in failure_states]
            if failed_packages:
                logging.error(f"Build failed. Found fatal statuses: {set(failed_packages)}")
                sys.exit(1)

            # Check for pending (anything not success and not failed)
            pending = [s for s in statuses if s not in success_states]

            if not pending:
                logging.info("All packages in repository are in a succeeded/final state.")
                break
            else:
                unique_pending = set(pending)
                mins_elapsed = int(elapsed_time // 60)
                logging.info(f"[{mins_elapsed}m elapsed] Build in progress. Packages processing: {len(pending)}. States: {unique_pending}")
                time.sleep(30)

        except ET.ParseError:
            logging.warning("Failed to parse build results XML. Retrying...")
            time.sleep(15)
        except Exception as e:
            logging.warning(f"Unexpected error during polling: {e}. Retrying...")
            time.sleep(15)


def print_registries(container_project):
    """
    Finds and print the all the file endings with '*.registry.txt' from a remote directory.
    """
    base_url = f"http://download.suse.de/ibs/{container_project.replace(':', ':/')}/containerfile/"
    logging.info(f"Searching for registry file at: {base_url}")

    try:
        response = requests.get(base_url)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')

        found_any = False
        for link in soup.find_all('a'):
            filename = link.get('href')
            if filename and filename.endswith('.registry.txt'):
                registry_url = f"{base_url}{filename}"
                logging.info(f"Found registry file: {filename}")
                file_response = requests.get(registry_url)
                file_response.raise_for_status()
                # Print the registry content as requested
                try:
                    print(file_response.text.splitlines()[1].split().pop())
                    found_any = True
                except IndexError:
                    logging.warning(f"Registry file {filename} seemed empty or malformed.")

        if not found_any:
            logging.warning("No *.registry.txt files found.")

    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to access build results URL: {e}")
        sys.exit(1)


def main():
    """
    Main function to parse arguments and run the update logic.
    """
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

    # Flag to track if we need to trigger a rebuild
    needs_rebuild = False

    # --- Edit Project Configuration (prjconf) ---
    if args.prefer:
        prjconf_cmd = ["osc", "-A", args.api_url, "meta", "prjconf", args.container_project]
        current_prjconf = run_osc_command(prjconf_cmd)

        prefer_line = f"Prefer: {args.prefer}"
        lines = current_prjconf.splitlines()
        new_lines = []
        found_prefer = False
        for line in lines:
            if line.strip().startswith("Prefer: container:suse-manager"):
                new_lines.append(prefer_line)
                found_prefer = True
            else:
                new_lines.append(line)
        if not found_prefer:
            new_lines.append(prefer_line)

        modified_prjconf = "\n".join(new_lines) + "\n"

        with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp_file:
            tmp_file.write(modified_prjconf)
            tmp_file_path = tmp_file.name

        upload_cmd = ["osc", "-A", args.api_url, "meta", "prjconf", args.container_project, "-F", tmp_file_path]
        run_osc_command(upload_cmd)
        os.remove(tmp_file_path)
        logging.info(f"Successfully updated project configuration for '{args.container_project}'.")
        needs_rebuild = True

    # --- Edit Project Metadata (meta) ---
    if args.mi_project and args.mi_repo_name:
        meta_cmd = ["osc", "-A", args.api_url, "meta", "prj", args.container_project]
        current_meta_xml = run_osc_command(meta_cmd)

        try:
            root = ET.fromstring(current_meta_xml)
            containerfile_repo = root.find(".//repository[@name='containerfile']")
            if containerfile_repo is None:
                raise ValueError("Could not find repository with name='containerfile' in the metadata.")

            path_to_modify = None
            for path_elem in containerfile_repo.findall("./path"):
                if re.match(r'SUSE:Maintenance:\d+', path_elem.get('project')):
                    path_to_modify = path_elem
                    break

            if path_to_modify is None:
                raise ValueError("Could not find a matching SUSE:Maintenance path to modify in the metadata.")

            path_to_modify.set('project', args.mi_project)
            path_to_modify.set('repository', args.mi_repo_name)

            modified_meta_xml = ET.tostring(root, encoding='unicode')

            with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp_file:
                tmp_file.write(modified_meta_xml)
                tmp_file_path = tmp_file.name

            upload_cmd = ["osc", "-A", args.api_url, "meta", "prj", args.container_project, "-F", tmp_file_path]
            run_osc_command(upload_cmd)
            os.remove(tmp_file_path)
            logging.info(f"Successfully updated project metadata for '{args.container_project}'.")
            needs_rebuild = True

        except ET.ParseError:
            logging.error("Failed to parse the project metadata XML. It might be malformed.")
            sys.exit(1)
        except ValueError as e:
            logging.error(e)
            sys.exit(1)

    # --- Forced Manual Rebuild ---
    # We trigger this regardless of whether OBS thought the metadata was 'new' or not.
    if needs_rebuild:
        rebuild_cmd = ["osc", "-A", args.api_url, "rebuild", args.container_project, "-r", "containerfile"]
        run_osc_command(rebuild_cmd)
        logging.info("Explicit rebuild triggered to bypass scheduler automation.")

        # Wait for the build to finish (with 90-minute timeout)
        wait_for_build_completion(args.api_url, args.container_project, timeout_minutes=90)
        print_registries(args.container_project)


if __name__ == "__main__":
    main()
