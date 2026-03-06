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

def get_mi_packages(api_url, mi_project, mi_repo_name):
    """Identifies binary RPM names from the MI using 'osc ls --binaries'."""
    sp_match = re.search(r'15-SP\d', mi_repo_name)
    if not sp_match:
        logging.error(f"Could not determine SP version from {mi_repo_name}")
        return []

    sp_version = sp_match.group(0)
    internal_repo = f"SUSE_SLE-{sp_version}_Update"
    logging.info(f"Targeting internal build repository: {internal_repo} for binaries.")

    cmd = [
        "osc", "-A", api_url, "ls", "--binaries",
        mi_project,
        "--arch", "x86_64",
        "--repo", f"{internal_repo}/"
    ]

    packages = set()
    try:
        output = run_osc_command(cmd).splitlines()
        for line in output:
            line = line.strip()
            if any(x in line for x in ["debuginfo", "debugsource", "patchinfo"]):
                continue
            if line.endswith(".rpm"):
                pkg_name = line.replace(".rpm", "")
                packages.add(pkg_name)
    except Exception as e:
        logging.error(f"Failed to list binaries for {internal_repo}: {e}")
        return []

    found_list = sorted(list(packages))
    logging.info(f"Successfully discovered {len(found_list)} binary RPMs: {found_list}")
    return found_list

def wait_for_build_completion(api_url, project, repository="containerfile", timeout_minutes=90):
    """Polls build results until success or failure states are reached."""
    logging.info("Initiating 30s safety wait for IBS scheduler...")
    time.sleep(30)
    start_time = time.time()
    timeout_seconds = timeout_minutes * 60
    cmd = ["osc", "-A", api_url, "results", project, "-r", repository, "--xml"]

    while True:
        elapsed = time.time() - start_time
        if elapsed > timeout_seconds:
            logging.error("Timeout: Build exceeded 90 minutes."); sys.exit(1)

        xml = run_osc_command(cmd)
        root = ET.fromstring(xml)
        statuses = [s.get('code') for s in root.findall(".//status")]
        if not statuses:
            time.sleep(15); continue
        if any(s in {'failed', 'broken', 'unresolvable'} for s in statuses):
            logging.error("Build failed in IBS."); sys.exit(1)
        if all(s in {'succeeded', 'excluded', 'disabled'} for s in statuses):
            logging.info("Build finished successfully."); break

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
        logging.error(f"Registry extraction failed: {e}")

def main():
    logging.basicConfig(level=logging.DEBUG, format='%(levelname)s: %(message)s', stream=sys.stderr)
    parser = argparse.ArgumentParser()
    parser.add_argument("--container-project", required=True)
    parser.add_argument("--api-url", default="https://api.suse.de")
    parser.add_argument("--prefer", help="Specific preference (e.g. init image version)")
    parser.add_argument("--mi-project", help="Maintenance Incident project ID")
    parser.add_argument("--mi-repo-name", help="External repository target name")
    parser.add_argument("--no-rebuild", action="store_true", help="Skip the rebuild and wait phase")
    args = parser.parse_args()

    needs_rebuild = False

    # --- Step 1: Update prjconf ---
    if args.mi_project and args.mi_repo_name:
        rpm_names = get_mi_packages(args.api_url, args.mi_project, args.mi_repo_name)
        dynamic_prefers = [f"Prefer: {rpm}:{args.mi_project}" for rpm in rpm_names]

        prjconf_text = run_osc_command(["osc", "-A", args.api_url, "meta", "prjconf", args.container_project])
        lines = [l for l in prjconf_text.splitlines() if ':SUSE:Maintenance:' not in l]

        final_lines = []
        injected = False
        for line in lines:
            final_lines.append(line)
            if line.strip().startswith('%if') and 'containerfile' in line and not injected:
                final_lines.extend(dynamic_prefers)
                if args.prefer:
                    final_lines.append(f"Prefer: {args.prefer}")
                injected = True
                logging.info(f"Injected {len(dynamic_prefers)} RPM preferences.")

        with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp:
            tmp.write("\n".join(final_lines) + "\n")
            tmp_path = tmp.name

        run_osc_command(["osc", "-A", args.api_url, "meta", "prjconf", args.container_project, "-F", tmp_path])
        os.remove(tmp_path)
        needs_rebuild = True

    # --- Step 2: Update Metadata ---
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

    # --- Step 3: Trigger Rebuild ---
    if needs_rebuild and not args.no_rebuild:
        run_osc_command(["osc", "-A", args.api_url, "rebuild", args.container_project, "-r", "containerfile"])
        wait_for_build_completion(args.api_url, args.container_project)
        print_registries(args.container_project)
    elif args.no_rebuild:
        logging.info("Skipping rebuild as --no-rebuild was specified.")

if __name__ == "__main__":
    main()