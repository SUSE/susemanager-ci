#!/usr/bin/python3

# Copyright (c) 2026 SUSE LLC
# Licensed under GPLv2

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
    """Executes osc commands and handles errors with logging."""
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

def get_mi_packages(api_url, mi_project):
    """
    Scans the MI project for source packages to identify what to prefer.
    Source discovery is used because binaries may not be published yet.
    """
    logging.info(f"Searching for source packages in {mi_project}...")
    cmd_list = ["osc", "-A", api_url, "ls", mi_project]

    try:
        source_output = run_osc_command(cmd_list).splitlines()
        # Filter: ignore empty lines and non-RPM entities like 'patchinfo'
        found_list = [p.strip() for p in source_output if p.strip() and p.strip() != "patchinfo"]

        if found_list:
            logging.info(f"Successfully discovered {len(found_list)} source packages in {mi_project}")
            return sorted(found_list)
    except Exception as e:
        logging.error(f"Failed to list sources in {mi_project}: {e}")

    return []

def wait_for_build_completion(api_url, project, repository="containerfile", timeout_minutes=90):
    """Polls build results until success or failure states are reached."""
    logging.info("Initiating 30s safety wait for IBS scheduler to recognize rebuild...")
    time.sleep(30)

    start_time = time.time()
    timeout_seconds = timeout_minutes * 60
    cmd = ["osc", "-A", api_url, "results", project, "-r", repository, "--xml"]

    while True:
        elapsed = time.time() - start_time
        if elapsed > timeout_seconds:
            logging.error(f"Timeout: Build exceeded {timeout_minutes} minutes."); sys.exit(1)

        xml = run_osc_command(cmd)
        root = ET.fromstring(xml)
        statuses = [s.get('code') for s in root.findall(".//status")]

        if not statuses:
            time.sleep(15); continue

        # Fatal states that stop the pipeline immediately
        if any(s in {'failed', 'broken', 'unresolvable'} for s in statuses):
            logging.error("Build failed in IBS. Review build logs."); sys.exit(1)

        # Success/Ignored states
        if all(s in {'succeeded', 'excluded', 'disabled'} for s in statuses):
            logging.info("All packages built or resolved successfully."); break

        logging.info(f"Build in progress... ({int(elapsed//60)}m elapsed)")
        time.sleep(45)

def print_registries(container_project):
    """Extracts and prints published container registry paths."""
    base_url = f"http://download.suse.de/ibs/{container_project.replace(':', ':/')}/containerfile/"
    try:
        r = requests.get(base_url); r.raise_for_status()
        soup = BeautifulSoup(r.text, 'html.parser')
        for link in soup.find_all('a'):
            fn = link.get('href')
            if fn and fn.endswith('.registry.txt'):
                content = requests.get(f"{base_url}{fn}").text
                print(content.splitlines()[1].split().pop())
    except Exception as e:
        logging.error(f"Registry path extraction failed: {e}")

def main():
    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s', stream=sys.stderr)
    parser = argparse.ArgumentParser(description="IBS Project Metadata & Config Editor")
    parser.add_argument("--container-project", required=True)
    parser.add_argument("--api-url", default="https://api.suse.de")
    parser.add_argument("--prefer", help="Specific preference (e.g. init image version)")
    parser.add_argument("--mi-project", help="Maintenance Incident project ID")
    parser.add_argument("--mi-repo-name", help="External repository target name")
    args = parser.parse_args()

    needs_rebuild = False

    # --- Step 1: Update Project Configuration (prjconf) ---
    if args.mi_project:
        # Discover packages in MI to generate dynamic Prefer rules
        mi_pkgs = get_mi_packages(args.api_url, args.mi_project)
        dynamic_prefers = [f"Prefer: {p}:{args.mi_project}" for p in mi_pkgs]
        prjconf_text = run_osc_command(["osc", "-A", args.api_url, "meta", "prjconf", args.container_project])
        # Clean old MI-related rules to avoid configuration bloat
        lines = [l for l in prjconf_text.splitlines() if ':SUSE:Maintenance:' not in l]

        final_lines = []
        injected = False
        for line in lines:
            final_lines.append(line)
            # Inject preference rules into the containerfile build repository block
            if 'if "%_repository" == "containerfile"' in line and not injected:
                final_lines.extend(dynamic_prefers)
                if args.prefer:
                    final_lines.append(f"Prefer: {args.prefer}")
                injected = True

        with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp:
            tmp.write("\n".join(final_lines) + "\n")
            tmp_path = tmp.name

        run_osc_command(["osc", "-A", args.api_url, "meta", "prjconf", args.container_project, "-F", tmp_path])
        os.remove(tmp_path)
        logging.info("Project configuration updated with source-based MI preferences.")
        needs_rebuild = True

    # --- Step 2: Metadata Update ---
    if args.mi_project and args.mi_repo_name:
        meta_text = run_osc_command(["osc", "-A", args.api_url, "meta", "prj", args.container_project])
        root = ET.fromstring(meta_text)
        container_repo = root.find(".//repository[@name='containerfile']")
        path_node = next((p for p in container_repo.findall("./path") if "SUSE:Maintenance:" in p.get('project')), None)

        if path_node is not None:
            path_node.set('project', args.mi_project)
            path_node.set('repository', args.mi_repo_name)
            with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp:
                tmp.write(ET.tostring(root, encoding='unicode'))
                tmp_path = tmp.name
            run_osc_command(["osc", "-A", args.api_url, "meta", "prj", args.container_project, "-F", tmp_path])
            os.remove(tmp_path)
            logging.info(f"Project Metadata updated to {args.mi_project}")
            needs_rebuild = True

    # --- Step 3: Trigger rebuild and wait ---
    if needs_rebuild:
        run_osc_command(["osc", "-A", args.api_url, "rebuild", args.container_project, "-r", "containerfile"])
        wait_for_build_completion(args.api_url, args.container_project)
        print_registries(args.container_project)

if __name__ == "__main__":
    main()
