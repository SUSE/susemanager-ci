# IBS/OBS Project Metadata & Configuration Editor (`edit.py`)

## Overview
This script automates the validation of SUSE Maintenance Incidents (MIs) within containerized environments. [cite_start]It programmatically modifies Open Build Service (OBS/IBS) projects to ensure the exact RPMs provided in an MI are prioritized during the build process[cite: 1, 8].

## Key Features

### 1. Dynamic Package Discovery
[cite_start]The script utilizes `osc ls -b` to inspect the targeted MI repository. [cite_start]It automatically generates `Prefer:` rules for **every RPM** found in the MI (e.g., PostgreSQL, ca-certificates), preventing "Shadowing" where the build service might otherwise default to standard repository versions.

### 2. Automated Project Configuration (`prjconf`)
* **Clean State**: Prior to each run, the script identifies and removes existing MI-related `Prefer:` rules to prevent configuration bloat.
* [cite_start]**Preference Enforcement**: Injects new rules directly into the relevant `%if` repository blocks to force the solver's decision[cite: 1, 8].

### 3. Forced Build Execution
To solve the issue of the IBS scheduler skipping builds when metadata remains identical, the script invokes an explicit `osc rebuild`. [cite_start]This ensures that rerunning a pipeline against the same MI always generates a fresh, traceable container image[cite: 1].

### 4. Robust Polling & Timeouts
* **90-Minute Timeout**: Prevents Jenkins executors from hanging indefinitely if the build service queue is delayed.
* **Success Verification**: Monitors build states until final resolution. [cite_start]Exits with an error if fatal states (`broken`, `failed`, `unresolvable`) are encountered[cite: 1].

## Usage
```bash
python3 edit.py \
  --container-project Devel:Galaxy:Manager:MUTesting:5.0 \
  --mi-project SUSE:Maintenance:42738 \
  --mi-repo-name SUSE_Updates_SLE-Product-SLES_15-SP6-LTSS_x86_64