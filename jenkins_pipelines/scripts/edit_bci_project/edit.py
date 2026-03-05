#!/usr/bin/python3

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
    Scans the MI project for build repositories containing RPMs.
    It automatically finds repositories like 'SUSE_SLE-15-SP6_Update'
    and extracts the package names.
    """
    logging.info(f"Searching for binary repositories in {mi_project}...")

    # 1. Get the list of all internal build targets
    repo_list_cmd = ["osc", "-A", api_url, "ls", "-b", mi_project]
    all_targets = run_osc_command(repo_list_cmd).splitlines()

    packages = set()
    # 2. Iterate through targets to find those containing RPMs
    # We look for targets ending in /x86_64
    for target in all_targets:
        if not target.endswith("/x86_64"):
            continue

        repo_name = target.split('/')[0]
        logging.info(f"Checking repository target: {repo_name}...")

        binary_list_cmd = ["osc", "-A", api_url, "ls", "-b", mi_project, repo_name, "x86_64"]
        try:
            binaries = run_osc_command(binary_list_cmd).splitlines()
            for line in binaries:
                line = line.strip()
                if line.endswith(".rpm") and not any(x in line for x in ["debuginfo", "debugsource"]):
                    # Extract name before the version (e.g. postgresql16-server)
                    match = re.match(r'^(.+?)-[0-9].*', line)
                    if match:
                        packages.add(match.group(1))
        except Exception:
            continue

    found_list = sorted(list(packages))
    if found_list:
        logging.info(f"Successfully discovered {len(found_list)} packages in {mi_project}")
    else:
        logging.warning(f"No RPMs discovered in {mi_project}. Verify build status in IBS.")

    return found_list

def wait_for_build_completion(api_url, project, repository="containerfile", timeout_minutes=90):
    logging.info("Initiating 30s safety wait for IBS scheduler...")
    time.sleep(30)
    start_time = time.time()
    timeout_seconds = timeout_minutes * 60
    cmd = ["osc", "-A", api_url, "results", project, "-r", repository, "--xml"]

    while True:
        if (time.time() - start_time) > timeout_seconds:
            logging.error(f"Timeout: Build exceeded {timeout_minutes} minutes."); sys.exit(1)

        xml = run_osc_command(cmd)
        root = ET.fromstring(xml)
        statuses = [s.get('code') for s in root.findall(".//status")]

        if not statuses:
            time.sleep(15); continue

        if any(s in {'failed', 'broken', 'unresolvable'} for s in statuses):
            logging.error("Build failed in IBS. Check logs."); sys.exit(1)

        if all(s in {'succeeded', 'excluded', 'disabled'} for s in statuses):
            logging.info("All packages built successfully."); break

        logging.info(f"Build in progress... ({int((time.time()-start_time)//60)}m elapsed)")
        time.sleep(45)

def print_registries(container_project):
    base_url = f"http://download.suse.de/ibs/{container_project.replace(':', ':/')}/containerfile/"
    try:
        r = requests.get(base_url); r.raise_for_status()
        soup = BeautifulSoup(r.text, 'html.parser')
        for link in soup.find_all('a'):
            fn = link.get('href')
            if fn and fn.endswith('.registry.txt'):
                content = requests.get(f"{base_url}{fn}").text
                # Print the second line's last word (the full registry path)
                print(content.splitlines()[1].split().pop())
    except Exception as e:
        logging.error(f"Registry extraction failed: {e}")

def main():
    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s', stream=sys.stderr)
    parser = argparse.ArgumentParser()
    parser.add_argument("--container-project", required=True)
    parser.add_argument("--api-url", default="https://api.suse.de")
    parser.add_argument("--prefer", help="Extra preference (e.g. init image version)")
    parser.add_argument("--mi-project")
    parser.add_argument("--mi-repo-name")
    args = parser.parse_args()

    needs_rebuild = False

    # --- Step 1: Update Project Config (prjconf) ---
    if args.mi_project:
        # DYNAMIC DISCOVERY: Find all packages in the MI to avoid Shadowing
        mi_pkgs = get_mi_packages(args.api_url, args.mi_project)
        dynamic_prefers = [f"Prefer: {p}:{args.mi_project}" for p in mi_pkgs]

        prjconf_text = run_osc_command(["osc", "-A", args.api_url, "meta", "prjconf", args.container_project])
        # Clean old MI rules
        lines = [l for l in prjconf_text.splitlines() if ':SUSE:Maintenance:' not in l]

        final_lines = []
        injected = False
        for line in lines:
            final_lines.append(line)
            # Inject inside the container repo block
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
        logging.info("Project Config updated with dynamic MI preferences.")
        needs_rebuild = True

    # --- Step 2: Update Project Metadata (meta prj) ---
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
            logging.info(f"Project Metadata updated to point to {args.mi_project}")
            needs_rebuild = True

    # --- Step 3: Trigger Build and Poll ---
    if needs_rebuild:
        run_osc_command(["osc", "-A", args.api_url, "rebuild", args.container_project, "-r", "containerfile"])
        wait_for_build_completion(args.api_url, args.container_project)
        print_registries(args.container_project)

if __name__ == "__main__":
    main()
