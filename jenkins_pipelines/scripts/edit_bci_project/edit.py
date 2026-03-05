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


def get_mi_packages(api_url, mi_project, mi_repo):
    """
    Fetches the list of binary packages available in the MI repository.
    """
    logging.info(f"Fetching package list from {mi_project}/{mi_repo} to generate dynamic preferences...")
    # 'osc ls -b' lists binaries (RPMs) in a project/repository
    cmd = ["osc", "-A", api_url, "ls", "-b", mi_project, mi_repo]
    output = run_osc_command(cmd)

    packages = set()
    for line in output.splitlines():
        if line.endswith(".rpm"):
            # Strip version/release info: postgresql16-server-16.11-150600.16.25.1.x86_64.rpm -> postgresql16-server
            match = re.match(r'^(.+?)-[0-9].*', line)
            if match:
                packages.add(match.group(1))

    found_pkgs = sorted(list(packages))
    logging.info(f"Found {len(found_pkgs)} packages in MI: {', '.join(found_pkgs[:5])}...")
    return found_pkgs


def wait_for_build_completion(api_url, project, repository="containerfile", timeout_minutes=90):
    """
    Polls the OBS project until all packages reach a final state or timeout.
    """
    logging.info(f"Waiting 30 seconds for the IBS/OBS scheduler to process the rebuild request...")
    time.sleep(30)

    logging.info(f"Starting to poll build results in project '{project}', repository '{repository}'...")

    start_time = time.time()
    timeout_seconds = timeout_minutes * 60
    cmd = ["osc", "-A", api_url, "results", project, "-r", repository, "--xml"]

    success_states = {'succeeded', 'excluded', 'disabled'}
    failure_states = {'failed', 'broken', 'unresolvable'}

    while True:
        elapsed_time = time.time() - start_time
        if elapsed_time > timeout_seconds:
            logging.error(f"Timeout reached: Build did not complete within {timeout_minutes} minutes.")
            sys.exit(1)

        try:
            xml_output = run_osc_command(cmd)
            root = ET.fromstring(xml_output)
            statuses = [status.get('code') for status in root.findall(".//status")]

            if not statuses:
                time.sleep(15)
                continue

            failed_packages = [s for s in statuses if s in failure_states]
            if failed_packages:
                logging.error(f"Build failed. Fatal statuses found: {set(failed_packages)}")
                sys.exit(1)

            pending = [s for s in statuses if s not in success_states]
            if not pending:
                logging.info("All packages reached a final state.")
                break
            else:
                mins_elapsed = int(elapsed_time // 60)
                logging.info(f"[{mins_elapsed}m elapsed] Build in progress. Remaining: {len(pending)}. States: {set(pending)}")
                time.sleep(30)

        except Exception as e:
            logging.warning(f"Unexpected error during polling: {e}. Retrying...")
            time.sleep(15)


def print_registries(container_project):
    """
    Scrapes and prints registry paths from the build artifacts.
    """
    base_url = f"http://download.suse.de/ibs/{container_project.replace(':', ':/')}/containerfile/"
    try:
        response = requests.get(base_url)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        for link in soup.find_all('a'):
            filename = link.get('href')
            if filename and filename.endswith('.registry.txt'):
                file_response = requests.get(f"{base_url}{filename}")
                print(file_response.text.splitlines()[1].split().pop())
    except Exception as e:
        logging.error(f"Failed to access build results: {e}")


def main():
    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s', stream=sys.stderr)

    parser = argparse.ArgumentParser(description="Automate editing OBS project metadata and configuration.")
    parser.add_argument("--container-project", required=True)
    parser.add_argument("--api-url", default="https://api.suse.de")
    parser.add_argument("--prefer", help="Custom Prefer rule (e.g., container version)")
    parser.add_argument("--mi-project", help="Maintenance Incident project")
    parser.add_argument("--mi-repo-name", help="Maintenance Incident repository name")
    args = parser.parse_args()

    needs_rebuild = False

    # --- Step 1: Manage Project Configuration (prjconf) ---
    prjconf_cmd = ["osc", "-A", args.api_url, "meta", "prjconf", args.container_project]
    current_prjconf = run_osc_command(prjconf_cmd)
    lines = current_prjconf.splitlines()

    # 1a. Identify Dynamic Preferences from MI
    dynamic_prefers = []
    if args.mi_project and args.mi_repo_name:
        mi_pkgs = get_mi_packages(args.api_url, args.mi_project, args.mi_repo_name)
        dynamic_prefers = [f"Prefer: {pkg}:{args.mi_project}" for pkg in mi_pkgs]

    # 1b. Clean existing MI preferences and add new ones
    # We remove any line that contains ':SUSE:Maintenance:' to avoid stale rules
    new_prjconf_lines = [l for l in lines if not re.search(r'Prefer:.*:SUSE:Maintenance:', l)]

    # Identify insertion point (inside the container repo check block)
    target_block_regex = r'%if.*containerfile'
    final_lines = []
    found_block = False

    for line in new_prjconf_lines:
        final_lines.append(line)
        if re.search(target_block_regex, line) and not found_block:
            # Inject dynamic MI preferences
            final_lines.extend(dynamic_prefers)
            # Inject explicit --prefer if provided
            if args.prefer:
                final_lines.append(f"Prefer: {args.prefer}")
            found_block = True

    modified_prjconf = "\n".join(final_lines) + "\n"

    with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp:
        tmp.write(modified_prjconf)
        tmp_path = tmp.name

    run_osc_command(["osc", "-A", args.api_url, "meta", "prjconf", args.container_project, "-F", tmp_path])
    os.remove(tmp_path)
    logging.info("Project configuration (prjconf) updated successfully.")
    needs_rebuild = True

    # --- Step 2: Manage Project Metadata (meta prj) ---
    if args.mi_project and args.mi_repo_name:
        meta_cmd = ["osc", "-A", args.api_url, "meta", "prj", args.container_project]
        current_meta_xml = run_osc_command(meta_cmd)
        root = ET.fromstring(current_meta_xml)

        containerfile_repo = root.find(".//repository[@name='containerfile']")
        path_to_modify = next((p for p in containerfile_repo.findall("./path")
                               if re.match(r'SUSE:Maintenance:\d+', p.get('project'))), None)

        if path_to_modify is not None:
            path_to_modify.set('project', args.mi_project)
            path_to_modify.set('repository', args.mi_repo_name)

            with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp:
                tmp.write(ET.tostring(root, encoding='unicode'))
                tmp_path = tmp.name

            run_osc_command(["osc", "-A", args.api_url, "meta", "prj", args.container_project, "-F", tmp_path])
            os.remove(tmp_path)
            logging.info(f"Project metadata (meta) updated to {args.mi_project}.")
            needs_rebuild = True

    # --- Step 3: Trigger Rebuild and Wait ---
    if needs_rebuild:
        run_osc_command(["osc", "-A", args.api_url, "rebuild", args.container_project, "-r", "containerfile"])
        wait_for_build_completion(args.api_url, args.container_project, timeout_minutes=90)
        print_registries(args.container_project)


if __name__ == "__main__":
    main()
