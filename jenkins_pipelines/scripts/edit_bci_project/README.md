# IBS/OBS Project Metadata & Configuration Editor (`edit.py`)

## Overview
This script automates the editing of Open Build Service (OBS) / Internal Build Service (IBS) project metadata and configurations. It is specifically designed to facilitate containerization testing for SUSE Multi-Linux Manager by programmatically injecting Maintenance Incident (MI) repositories and enforcing package preferences prior to a build.

## Architecture & Design
The script is written in Python 3 and bridges standard OS operations with external HTTP requests. It utilizes `subprocess` to interface securely with the `osc` CLI tool, `xml.etree.ElementTree` for precise XML manipulation, and `requests` + `BeautifulSoup4` for web scraping build artifacts.

### Key Components

* **`run_osc_command(command, input_data)`**:
  A centralized helper function that executes `osc` commands inside a neutral temporary directory. It captures standard output and standard error, providing robust error logging if the command fails.
* **Automatic Repository Resolution (`get_mi_repo_names`)**:
  Instead of requiring manual repository input, the script now accepts a `--mi-project` (e.g., `SUSE:Maintenance:12345`). It fetches that project's metadata and dynamically resolves the required repository names by filtering out Maintenance/Update paths and formatting the strings (replacing colons with underscores). This function supports **multi-repository** output if the MI contains multiple base targets.
* **Project Configuration (`prjconf`) Editing**:
  If a `--prefer` argument is provided, the script fetches the current project configuration. It parses the text line-by-line, dynamically replacing or appending the `Prefer:` rule (e.g., pinning a specific version) before uploading the modified configuration back to IBS.
* **Project Metadata (`meta`) Editing & Cleanup**:
  The script fetches the target project's XML metadata and targets the `<repository name='containerfile'>` node.
* **Leftover Removal**: It scans for any existing `<path project="SUSE:Maintenance:..." />` entries and removes them entirely to ensure a clean state.
* **Injection**: It injects a new `<path>` element for **every** repository name resolved by the resolution logic.
* **Binary Management (`osc wipebinaries`)**:
  Immediately following a metadata update, the script executes `osc wipebinaries --all`. This forces the IBS scheduler to discard old build artifacts and ensures that the subsequent build is performed strictly against the newly injected MI repositories.
* **`wait_for_build_completion(api_url, project)`**:
  A smart polling mechanism that waits for the IBS scheduler to process the update.
* **Safety Sleep**: Initiates a 60-second sleep to ensure the scheduler has time to invalidate previous build states.
* **State Evaluation**: Continuously queries `osc results`, tracking packages until they all reach a final state (`succeeded`, `excluded`, `disabled`). If any package enters a fatal state (`failed`, `broken`, `unresolvable`), the script exits with an error.
* **Build Validation & Dependency Audit** (`print_mi_build_info`):
  Once a build reaches the succeeded state, the script performs a deep audit of the build environment. For every package and architecture, it executes osc buildinfo and parses the resulting XML to identify and print all build dependencies (bdep) that were successfully sourced from the validated mi_project. The user will still need to confirm visually that the maintenance fixes were actually utilized during the container build.
* **`print_registries(container_project)`**:
  Once the build succeeds, this function queries the IBS download directory. Using `BeautifulSoup`, it scrapes the page for generated `*.registry.txt` files, parses them, and prints the exact registry paths/tags to the console for downstream automation.
