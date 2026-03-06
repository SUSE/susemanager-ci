# IBS/OBS Project Metadata & Configuration Editor (`edit.py`)

## Overview
This script automates Maintenance Incident (MI) validation for SUSE Manager containers. It programmatically reconfigures Internal Build Service (IBS) projects to ensure new RPMs from an MI are prioritized over standard system updates during the build process.

## Architecture
The script performs three critical phases to ensure a clean and valid test environment:

### 1. Dynamic Package Discovery
Instead of hardcoding package names, the script scans the MI project (`osc ls -b`) to identify every RPM currently being tested. This allows it to automatically handle PostgreSQL updates today and security fixes (like `ca-certificates`) tomorrow without manual code changes.

### 2. Solver Preference Enforcement (`prjconf`)
To prevent "Shadowing" (where IBS chooses a standard repo package over our test package because they share the same version), the script injects `Prefer:` rules for every discovered RPM.
* Example: `Prefer: postgresql16-server:SUSE:Maintenance:42738`

### 3. Forced Build Triggering
Because the IBS scheduler may skip rebuilds if metadata remains identical, the script invokes an explicit `osc rebuild`. Combined with a **90-minute timeout** and success polling, this ensures the Jenkins pipeline only proceeds if a fresh container was successfully generated.

## Requirements
* `osc` CLI configured with credentials for `api.suse.de`.
* Python packages listed in `requirements.txt`.