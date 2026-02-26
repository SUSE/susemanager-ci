# IBS/OBS Project Metadata & Configuration Editor (`edit.py`)

## Overview
This script automates the editing of Open Build Service (OBS) / Internal Build Service (IBS) project metadata and configurations. It is specifically designed to facilitate containerization testing for SUSE Multi-Linux Manager by programmatically injecting Maintenance Incident (MI) repositories and enforcing package preferences prior to a build.

## Architecture & Design
The script is written in Python 3 and bridges standard OS operations with external HTTP requests. It utilizes `subprocess` to interface securely with the `osc` CLI tool, `xml.etree.ElementTree` for precise XML manipulation, and `requests` + `BeautifulSoup4` for web scraping build artifacts.

### Key Components

* **`run_osc_command(command, input_data)`**:
  A centralized helper function that executes `osc` commands inside a neutral temporary directory. It captures standard output and standard error, providing robust error logging if the command fails.
* **Project Configuration (`prjconf`) Editing**:
  If a `--prefer` argument is provided, the script fetches the current project configuration. It parses the text line-by-line, dynamically replacing or appending the `Prefer:` rule (e.g., pinning a specific version) before uploading the modified configuration back to IBS.
* **Project Metadata (`meta`) Editing**:
  The script fetches the project's XML metadata and searches specifically for the `<repository name='containerfile'>` node. It uses regular expressions to locate the existing Maintenance Incident path (`SUSE:Maintenance:\d+`) and overrides the `project` and `repository` attributes with the newly provided MI parameters. The updated XML is then written to a temporary file and uploaded.
* **`wait_for_build_completion(api_url, project)`**:
  A smart polling mechanism that waits for the IBS scheduler to process the updated metadata.
    * **Safety Sleep**: It initiates a 60-second sleep before polling to ensure previous build states are properly invalidated by the scheduler.
    * **State Evaluation**: It continuously queries `osc results`, tracking packages until they all reach a final state (`succeeded`, `excluded`, `disabled`). If any package enters a fatal state (`failed`, `broken`, `unresolvable`), the script exits with an error.
* **`print_registries(container_project)`**:
  Once the build succeeds, this function queries the IBS download HTML directory. Using `BeautifulSoup`, it scrapes the page for generated `*.registry.txt` files, downloads them, and extracts the exact registry paths/tags produced by the build. This information is then printed to the console to be consumed by downstream processes.
