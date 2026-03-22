#!/usr/bin/python3

# Copyright (c) 2026 SUSE LLC
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
    logging.debug(f"Running command: {' '.join(command)}")

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


def get_mi_repo_names(api_url, mi_project):
    """
    Retrieves a list of codestreams by inspecting the metadata of the mi-project.
    Filters out Maintenance/Updates and replaces colons with underscores.
    """
    logging.info(f"Resolving codestreams for maintenance project: {mi_project}")
    cmd = ["osc", "-A", api_url, "meta", "prj", mi_project]
    meta_xml = run_osc_command(cmd)

    try:
        root = ET.fromstring(meta_xml)
        paths = root.findall(".//repository/path")

        resolved_repos = []
        for p in paths:
            project_val = p.get('project')
            if project_val and not re.match(r'^(SUSE:Maintenance|SUSE:Updates)', project_val):
                repo_name = project_val.replace(":", "_")
                if repo_name not in resolved_repos:
                    resolved_repos.append(repo_name)

        if not resolved_repos:
            raise ValueError(f"Could not find any valid base projects in {mi_project} metadata.")

        logging.info(f"Resolved codestreams: {', '.join(resolved_repos)}")
        return resolved_repos

    except (ET.ParseError, ValueError) as e:
        logging.error(f"Error resolving repo names: {e}")
        sys.exit(1)


def verify_metadata(api_url, container_project, mi_project):
    """
    Re-fetches the project metadata from OBS and verifies that:
    - No stale SUSE:Maintenance paths remain (other than the expected mi_project)
    - The expected mi_project path is present in the containerfile repository
    Exits with an error if verification fails.
    """
    logging.info("Verifying metadata was correctly applied...")
    verified_xml = run_osc_command(["osc", "-A", api_url, "meta", "prj", container_project])
    verified_root = ET.fromstring(verified_xml)
    verified_paths = [
        p.get('project')
        for p in verified_root.findall(".//repository[@name='containerfile']/path")
    ]

    mi_pattern = re.compile(r'^SUSE:Maintenance:\d+$').match
    stale_mi = [
        p for p in verified_paths
        if p != mi_project and p and mi_pattern(p)
    ]
    if stale_mi:
        logging.error(f"Metadata verification failed: stale MI paths still present: {stale_mi}")
        sys.exit(1)

    if mi_project not in verified_paths:
        logging.error(f"Metadata verification failed: expected MI path '{mi_project}' not found.")
        sys.exit(1)

    logging.info("Metadata verification passed.")


def wait_for_build_completion(api_url, project, repository="containerfile"):
    """
    Polls the OBS project until all packages reach a final state.
    Returns the final status XML for further processing.
    """
    logging.info("Metadata updated. Waiting 60 seconds for the IBS/OBS scheduler to trigger rebuilds...")
    time.sleep(60)

    logging.info(f"Starting to poll build results in project '{project}', repository '{repository}'...")

    cmd = ["osc", "-A", api_url, "results", project, "-r", repository, "--xml"]

    success_states = {'succeeded', 'excluded', 'disabled'}
    failure_states = {'failed', 'broken'}

    while True:
        try:
            xml_output = run_osc_command(cmd)
            root = ET.fromstring(xml_output)

            # Extract all 'code' attributes from <status> tags
            statuses = [status.get('code') for status in root.findall(".//status")]

            if not statuses:
                logging.info("No package status found yet. Waiting...")
                time.sleep(20)
                continue

            if any(s in failure_states for s in statuses):
                logging.error(f"Build failed. Found fatal statuses: {set(statuses) & failure_states}")
                sys.exit(1)

            if all(s in success_states for s in statuses):
                logging.info("All packages in repository are in a succeeded/final state.")
                return root

            logging.info(f"Build in progress. Packages processing: {len([s for s in statuses if s not in success_states])}")
            time.sleep(20)

        except Exception as e:
            logging.warning(f"Error during polling: {e}. Retrying...")
            time.sleep(10)


def print_mi_build_info(api_url, project, mi_project, results_xml, repository="containerfile"):
    """
    For each package and architecture, runs 'osc buildinfo' and prints dependencies
    originating from the mi_project.
    """
    logging.info(f"Checking build dependencies from {mi_project}...")

    # Iterate through each result entry in the results XML to get architectures
    for result in results_xml.findall(".//result"):
        arch = result.get('arch')

        # Iterate through each status scoped to the current result to avoid cross-pairing
        for status in result.findall("./status"):
            package = status.get('package')
            code = status.get('code')

            # Skip if we are missing critical information or if the build didn't succeed
            if not package or not arch or code != 'succeeded':
                continue

            logging.info(f"Retrieving buildinfo for {package} ({arch})...")
            # Ensure all items in this list are strings to avoid "NoneType found" errors
            cmd = ["osc", "-A", str(api_url), "buildinfo", str(project), str(package), str(repository), str(arch)]

            try:
                info_xml = run_osc_command(cmd)
                info_root = ET.fromstring(info_xml)

                # Find all bdeps where project matches mi_project
                bdeps = info_root.findall(f".//bdep[@project='{mi_project}']")

                for bdep in bdeps:
                    name = bdep.get('name')
                    version = bdep.get('version')
                    release = bdep.get('release')
                    b_arch = bdep.get('arch')
                    repo = bdep.get('repository')

                    print(f"  <bdep name=\"{name}\" version=\"{version}\" release=\"{release}\" arch=\"{b_arch}\" project=\"{mi_project}\" repository=\"{repo}\"/>")

            except Exception as e:
                logging.error(f"Failed to process buildinfo for {package}: {e}")


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
                file_response = requests.get(registry_url)
                file_response.raise_for_status()
                try:
                    print(file_response.text.splitlines()[1].split().pop())
                    found_any = True
                except IndexError:
                    pass

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
    parser.add_argument("--container-project", required=True, help="The name of the OBS project.")
    parser.add_argument("--api-url", default="https://api.suse.de", help="The OBS API URL.")
    parser.add_argument("--prefer", help="The value for the 'Prefer' rule in prjconf.")
    parser.add_argument("--mi-project", help="The project name of the MI to validate.")
    args = parser.parse_args()

    # --- Edit Project Configuration ---
    if args.prefer:
        prjconf_cmd = ["osc", "-A", args.api_url, "meta", "prjconf", args.container_project]
        current_prjconf = run_osc_command(prjconf_cmd)

        prefer_line = f"Prefer: {args.prefer}"
        lines = current_prjconf.splitlines()
        new_lines = [prefer_line if l.strip().startswith("Prefer: container:suse-manager") else l for l in lines]
        if not any(l.strip().startswith("Prefer: container:suse-manager") for l in lines):
            new_lines.append(prefer_line)

        with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp:
            tmp.write("\n".join(new_lines) + "\n")
            tmp.flush()
            os.fsync(tmp.fileno())
            upload_cmd = ["osc", "-A", args.api_url, "meta", "prjconf", args.container_project, "-F", tmp.name]
            run_osc_command(upload_cmd)
        os.remove(tmp.name)

    # --- Edit Project Metadata ---
    if args.mi_project:
        mi_repo_names = get_mi_repo_names(args.api_url, args.mi_project)
        meta_xml = run_osc_command(["osc", "-A", args.api_url, "meta", "prj", args.container_project])

        try:
            root = ET.fromstring(meta_xml)
            repo_node = root.find(".//repository[@name='containerfile']")

            # Remove existing MI paths (collect first to avoid mutating during iteration)
            mi_paths = [
                p for p in repo_node.findall("./path")
                if re.match(r'SUSE:Maintenance:\d+', p.get('project', ''))
            ]
            for p in mi_paths:
                repo_node.remove(p)

            # Insert before the last path element
            remaining_paths = repo_node.findall("./path")
            insertion_index = list(repo_node).index(remaining_paths[-1]) if remaining_paths else 0

            for i, repo_name in enumerate(mi_repo_names):
                new_path = ET.Element('path', {'project': args.mi_project, 'repository': repo_name})
                repo_node.insert(insertion_index + i, new_path)

            with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp:
                ET.indent(root)
                xml_content = ET.tostring(root, encoding='unicode')
                tmp.write(xml_content)
                tmp.flush()
                os.fsync(tmp.fileno())
                run_osc_command(["osc", "-A", args.api_url, "meta", "prj", args.container_project, "-F", tmp.name])
            os.remove(tmp.name)

            # --- Verify metadata was correctly applied before wiping ---
            verify_metadata(args.api_url, args.container_project, args.mi_project)

            # Wipe and Wait
            run_osc_command(["osc", "-A", args.api_url, "wipebinaries", "--all", args.container_project])
            final_results = wait_for_build_completion(args.api_url, args.container_project)

            # --- Verification Step ---
            print_mi_build_info(args.api_url, args.container_project, args.mi_project, final_results)
            print_registries(args.container_project)

        except Exception as e:
            logging.error(f"Error: {e}")
            sys.exit(1)


if __name__ == "__main__":
    main()
