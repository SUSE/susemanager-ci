# maintenance_json_generator.py

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Usage](#usage)
- [Output](#output)
- [Logging](#logging)
- [Functions](#functions)
- [Error Handling](#error-handling)
- [Dependencies](#dependencies)
- [License](#license)

---

## Overview

This Python script automates the process of gathering and processing open QAM
(Quality Assurance Maintenance) requests for SUSE Linux Enterprise Server (SLES)
that affect SUSE Manager. The output is a JSON file, which can be fed into the
BV (Build Validation) testsuite pipeline for further testing. It supports SUSE
Manager / MLM 4.3, 5.0, 5.1 and 5.2 (including 5.2 beta).

The script allows users to input Maintenance Incident (MI) IDs and generates the
appropriate repository information for the selected version's nodes (servers,
proxies, and clients). The supported `--version` values are: `43`, `50-micro`,
`50-sles`, `51-micro`, `51-sles`, `52-micro`, `52-sles`, `52-micro-beta`,
`52-sles-beta`.

## Features

- Support for SUSE Manager / MLM 4.3, 5.0, 5.1 and 5.2 (including 5.2 beta): the
version is selected via `--version`.
- Flexible MI ID Input: MI IDs can be provided via CLI arguments or by reading
from a file.
- Custom Repository Generation: Outputs a JSON file containing repository
information for the SUSE Manager BV testsuite pipeline.
- Embargo Checks: The script has an option to reject Maintenance Incidents (MIs)
that are under embargo.
- SLFO client tools for `sles160_minion` / `slmicro62_minion`:
  - Stable `51-*` / `52-sles` / `52-micro`: use `--slfo-pull-request <id>` to
    inject a `:PullRequest:/<id>` client-tools URL (independent of MI IDs).
  - Beta `52-sles-beta` / `52-micro-beta`: a static `:ToTest` URL is baked in
    and applied automatically; `--slfo-pull-request` is rejected for beta
    versions because the Beta project cannot toggle maintenance on/off under
    the git workflow.

## Usage

Command-Line Arguments

The script accepts several command-line arguments to control its behavior.

```bash
python3.11 maintenance_json_generator.py [options]
```

Options:

`-v`, `--version`: Specifies the SUSE Manager version. Options are `43` for SUSE
Manager 4.3, `50-micro` / `50-sles` for 5.0, `51-micro` / `51-sles` for 5.1, and `52-micro` / `52-sles` for 5.2 (including `52-micro-beta` / `52-sles-beta`). Default is `51-sles`.
`-i`, `--mi_ids`: A space-separated list of MI IDs.
`-f`, `--file`: Path to a file containing MI IDs, each on a new line.
`-e`, `--no_embargo`: Reject any MIs that are currently under embargo.
`--slfo-pull-request`: SLFO PullRequest id for `sles160_minion` and `slmicro62_minion` on stable 5.1 / 5.2 only (independent of MI ids). Rejected for `-beta` versions, which receive a fixed `:ToTest` URL automatically. In `custom_repositories.json`, those entries use the inner key pattern `slfo_pr_<id>` (not the bare PR id) so they cannot collide with MI id keys.

Example:

```bash
python3.11 maintenance_json_generator.py --version 50-micro --mi_ids 1234 5678 --file mi_ids.txt --no_embargo
```

This command will:

1. Run the script for SUSE Manager 5.0 (`--version 50-micro`).
2. Use MI IDs 1234 and 5678 along with any additional MI IDs from the file
mi_ids.txt.
3. Reject any MIs that are under embargo (`--no_embargo`).

## Output

The script generates a file named custom_repositories.json, which contains the
repository data for the provided MI IDs.

For **`43`**, **`50-micro`**, and **`50-sles`**, the output always includes static Salt image
repository URLs for **`slmicro60_minion`** and **`slmicro61_minion`** (`slmicro60_salt`,
`slmicro61_salt`, `slmicro6_salt_bundle`) in addition to MI-based maintenance URLs.

For **`52-sles-beta`** and **`52-micro-beta`**, the output always includes fixed `:ToTest`
client-tools URLs independently of MI IDs. **`slmicro60_minion`** and **`slmicro61_minion`**
use the **SL-Micro-6** MultiLinuxManagerTools-Beta **`:ToTest`** path (inner key
`slmicro6_client_tools`). **`slmicro62_minion`** and **`sles160_minion`** share the same
**SLES-16** MultiLinuxManagerTools-Beta **`:ToTest`** path under the inner key
**`sles16_client_tools`**. In addition, **`52-sles-beta`** always includes fixed `http://`
`server` and `proxy` ToTest image repos; path fragments live in
**`v52_uyuni_tools_sles_static_repos_beta`** and are prefixed with **`IBS_URL_PREFIX`** in
**`get_v52_static_and_client_tools`** (they are not pre-built `http://` strings in the dict).
URLs resolve under
`SUSE:/SLE-15-SP7:/Update:/Products:/MultiLinuxManager52:/ToTest/images-SP7/repo/`
(`SUSE-Multi-Linux-Manager-Server-SLE-5.2-POOL-x86_64-Media1/` and
`SUSE-Multi-Linux-Manager-Proxy-SLE-5.2-POOL-x86_64-Media1/`). **`52-micro-beta`** pins
`server_uyuni_tools` and `proxy_uyuni_tools` to the `http://`
`SLFO:/Products:/Multi-Linux-Manager:/5.2:/ToTest/product/repo/` tree
(`Multi-Linux-Manager-Server-5.2-x86_64/` and `Multi-Linux-Manager-Proxy-5.2-x86_64/`). On the stable `51-*` / `52-sles` / `52-micro` flows,
equivalent URLs for `sles160_minion` / `slmicro62_minion` are only added when
`--slfo-pull-request <id>` is provided.

## Logging

The script includes basic logging for informational messages. To enable logging,
ensure the setup_logging function is called at the beginning of the script. Log
messages will display timestamped INFO-level messages.

## Functions

### Main Functions

- `parse_cli_args()`: Parses the command-line arguments using argparse.
- `merge_mi_ids()`: Merges MI IDs provided from the CLI or file input.
- `read_mi_ids_from_file()`: Reads MI IDs from a file.
- `clean_mi_ids()`: Cleans and formats MI IDs for consistency.

### Repository Data

Repository definitions live under
[repository_versions/](repository_versions), one module per major version:

- `v43_nodes.py`: server/proxy (`v43_nodes`), client tools (`v43_client_tools`),
  static Salt image repos (`v43_static_slmicro_salt_repositories`), and the
  helper `get_v43_nodes_sorted()`.
- `v50_nodes.py`: base node sets for SL Micro / SLES (`v50_micro_nodes`,
  `v50_sles_nodes`) and the helper
  `get_v50_nodes_sorted(v43_client_tools, variant)`.
- `v51_nodes.py` / `v52_nodes.py`: the helpers
  `get_v51_static_and_client_tools(variant)` and
  `get_v52_static_and_client_tools(variant, beta)`, which return a
  `(static_repos, dynamic_repos)` pair per variant. For **`52-sles-beta`**, fixed
  ToTest **server** / **proxy** image URLs are defined in
  `v52_uyuni_tools_sles_static_repos_beta` (separate from MI-based
  `v52_uyuni_tools_sles_repos_beta`). For **`52-micro-beta`** / **`52-sles-beta`**, dynamic
  client minions include **`opensuse160arm_minion`** (`MultiLinuxManagerTools-Beta_SLE-16_aarch64`),
  alongside **`opensuse156arm_minion`** (SLE-15 aarch64), in **`v52_nodes_dynamic_client_tools_repos_beta`**.

`repository_versions/__init__.py` aggregates everything into the
`nodes_by_version` mapping, whose keys are exactly the strings accepted by
`--version` (`43`, `50-micro`, `50-sles`, `51-micro`, `51-sles`, `52-micro`,
`52-sles`, `52-micro-beta`, `52-sles-beta`) and whose values are
`{"static": ..., "dynamic": ...}` dicts consumed by the main script.

## Error Handling

- If no MI IDs are provided via CLI or file, the script will print an error
message and halt execution.
- Invalid MI IDs or missing files will result in appropriate error messages.

## Dependencies

The following Python libraries are required to run this script:

- `argparse`: For parsing command-line arguments (standard library).
- `functools`: For the cache decorator (standard library).
- `json`: For generating JSON output (standard library).
- `requests`: For sending HTTP requests.
- `logging`: For logging informational messages (standard library).

### External Dependencies

`ibs_osc_client`: This module is used to interact with the IBS (Internal Build
Service) Open Service Client.

## License

This script is licensed under the [MIT License](https://opensource.org/licenses/MIT).
