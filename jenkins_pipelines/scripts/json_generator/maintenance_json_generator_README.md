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
Manager / MLM 4.3, 5.0, 5.1, 5.2 (stable), and 5.3 beta placeholders.

The script allows users to input Maintenance Incident (MI) IDs and generates the
appropriate repository information for the selected version's nodes (servers,
proxies, and clients). The supported `--version` values are: `43`, `50-micro`,
`50-sles`, `51-micro`, `51-sles`, `52-micro`, `52-sles`, `53-micro-beta`,
`53-sles-beta`.

## Features

- Support for SUSE Manager / MLM 4.3, 5.0, 5.1, 5.2 (stable), and 5.3 beta placeholders: the
version is selected via `--version`.
- Flexible MI ID Input: MI IDs can be provided via CLI arguments or by reading
from a file.
- Custom Repository Generation: Outputs a JSON file containing repository
information for the SUSE Manager BV testsuite pipeline.
- Embargo Checks: The script has an option to reject Maintenance Incidents (MIs)
that are under embargo.
- SLFO PullRequests: `-s` / `--slfo-pull-request` takes any number of ids and works
  out by itself where each one belongs, so the ids of a build validation can be
  dropped in as they come without sorting them by hand.
  - Stable `51-*` / `52-sles` / `52-micro`: every id is looked up on IBS and applied
    to the nodes of the project that publishes it (independent of MI IDs).
  - Beta `53-sles-beta` / `53-micro-beta`: static `:ToTest` URLs are baked in
    and applied automatically; `--slfo-pull-request` is rejected for beta
    versions because the Beta project cannot toggle maintenance on/off under
    the git workflow.

## Usage

Command-Line Arguments

The script accepts several command-line arguments to control its behavior.

```bash
python3 maintenance_json_generator.py [options]
```

The script needs Python 3.10 or newer; do not call a pinned point release such
as `python3.11`, it is not packaged on every host (Leap 16.0 ships 3.13 only).
The Jenkins pipelines call plain `python3` for the same reason.

Running the script with no arguments at all prints this help and exits.

Options:

`-v`, `--version`: **Mandatory.** Specifies the SUSE Manager version. Options are `43` for SUSE
Manager 4.3, `50-micro` / `50-sles` for 5.0, `51-micro` / `51-sles` for 5.1, `52-micro` / `52-sles` for 5.2 (stable), and `53-micro-beta` / `53-sles-beta` for 5.3 beta placeholders. There is no default: the version always has to be named, so that a JSON is never silently generated for the wrong product.
`-i`, `--mi_ids`: A space-separated list of MI IDs.
`-f`, `--file`: Path to a file containing MI IDs, each on a new line.
`-e`, `--no_embargo`: Reject any MIs that are currently under embargo.
`-s`, `--slfo-pull-request`: A space-separated (or comma-separated) list of SLFO PullRequest
ids, on stable 5.1 / 5.2 only (independent of MI ids). Rejected for `-beta` versions, which
receive a fixed `:ToTest` URL automatically.

Each id is looked up on IBS and applied to the project that publishes it - the two families
are numbered independently, so the layout on IBS is the only reliable way to tell them apart:

| Project | Applied to | Inner key |
| --- | --- | --- |
| `SLFO:/Products:/MultiLinuxManagerTools:/PullRequest:/<id>:/SLES` | `sles160_minion`, `slmicro62_minion` (x86_64), `opensuse160arm_minion` (aarch64) | `slfo_pr_{id}_{minion}_{arch}` |
| `SLFO:/Products:/Multi-Linux-Manager:/<5.x>:/Packages:/PullRequest:/<id>:/SL-Micro` | `server`, `proxy` of the `-micro` variant | `slfo_pr_{id}_{server,proxy,retail}_uyuni_tools` |

A PullRequest repo **supersedes** the `:ToTest` repo it corresponds to rather than being
added next to it, so the node cannot install the `:ToTest` content instead of the one under
test. The keys include the minion name and architecture so that each repository has a unique
name, preventing race conditions where minions could pick up the wrong-architecture repository.

An id that exists in neither project aborts the run: a typo must not silently produce a JSON
that falls back to `:ToTest`. A Packages PullRequest passed to a `-sles` version is skipped
with a log line instead, so the same list of ids can be used for both variants. Once a
PullRequest is merged its project disappears from IBS - drop the id, and the `:ToTest`
fallback then carries the merged content.

Example:

```bash
python3 maintenance_json_generator.py --version 50-micro --mi_ids 1234 5678 --file mi_ids.txt --no_embargo
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
`slmicro61_salt`) in addition to MI-based maintenance URLs.

On the stable **`51-*`** and **`52-*`** flows, **`sles160_minion`**, **`slmicro62_minion`**
(x86_64) and **`opensuse160arm_minion`** (aarch64) receive the SLES-16
MultiLinuxManagerTools **`:ToTest`** client tools under the inner key
**`sles16_client_tools`**. SLE 16 has no maintenance project, so those minions get no
MI-based URLs; a client-tools `--slfo-pull-request` id replaces that `:ToTest` entry.

On **`52-micro`** (and **`51-micro`**), **`server`** and **`proxy`** get their
Multi-Linux-Manager product repos from the **`:ToTest`** tree under the inner keys
**`server_uyuni_tools`**, **`proxy_uyuni_tools`** and **`retail_uyuni_tools`**; a
Packages `--slfo-pull-request` id replaces those three with the
**`:Packages:/PullRequest:/<id>:/SL-Micro`** repos. Whatever is left pointing at
**`:ToTest`** is checked for existence and logged as a warning if it is not published.

For **`53-sles-beta`** and **`53-micro-beta`**, the output always includes fixed `:ToTest`
client-tools URLs independently of MI IDs. **`slmicro62_minion`** and **`sles160_minion`**
share the same **SLES-16** MultiLinuxManagerTools-Beta **`:ToTest`** path under the inner key
**`sles16_client_tools`**, and **`opensuse160arm_minion`** gets the aarch64 repo of the same
path under that key. Other client minions receive MI-based maintenance URLs from the
dynamic map. In addition, **`53-sles-beta`** always includes fixed `http://` ToTest
image repos for **`server`** and **`proxy`**; path fragments live in
**`v53_uyuni_tools_sles_static_repos_beta`** and are prefixed with **`IBS_URL_PREFIX`** in
**`get_v53_static_and_client_tools`**. URLs resolve under
`SUSE:/SLE-15-SP7:/Update:/Products:/MultiLinuxManager53:/ToTest/images-SP7/repo/`
(`SUSE-Multi-Linux-Manager-Server-SLE-5.3-POOL-x86_64-Media1/` and
`SUSE-Multi-Linux-Manager-Proxy-SLE-5.3-POOL-x86_64-Media1/`). **`53-micro-beta`** pins
`server_uyuni_tools` and `proxy_uyuni_tools` to the
`http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.3:/ToTest/product/repo/` tree
(`Multi-Linux-Manager-Server-5.3-x86_64/` and `Multi-Linux-Manager-Proxy-5.3-x86_64/`).

**Example SLFO PullRequest Output:**

With `--slfo-pull-request 362` (a MultiLinuxManagerTools PullRequest), the generated JSON
includes unique repository keys, and the `sles16_client_tools` entry of those minions is
gone because the PullRequest repo replaced it:

```json
{
  "sles160_minion": {
    "slfo_pr_362_sles160_x86_64": "http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools:/PullRequest:/362:/SLES/product/repo/Multi-Linux-ManagerTools-SLE-16-x86_64/"
  },
  "slmicro62_minion": {
    "slfo_pr_362_slmicro62_x86_64": "http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools:/PullRequest:/362:/SLES/product/repo/Multi-Linux-ManagerTools-SLE-16-x86_64/"
  },
  "opensuse160arm_minion": {
    "slfo_pr_362_opensuse160arm_aarch64": "http://download.suse.de/ibs/SUSE:/SLFO:/Products:/MultiLinuxManagerTools:/PullRequest:/362:/SLES/product/repo/Multi-Linux-ManagerTools-SLE-16-aarch64/"
  }
}
```

The key format `slfo_pr_{id}_{minion}_{arch}` ensures that each minion's repository has a globally unique name within the JSON, preventing repository collisions in downstream tooling.

A Multi-Linux-Manager Packages PullRequest on a `-micro` version lands on the server and
proxy instead, for example `--version 52-micro --slfo-pull-request 65`:

```json
{
  "server": {
    "slfo_pr_65_server_uyuni_tools": "http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.2:/Packages:/PullRequest:/65:/SL-Micro/product/repo/Multi-Linux-Manager-Server-5.2-x86_64/"
  },
  "proxy": {
    "slfo_pr_65_proxy_uyuni_tools": "http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.2:/Packages:/PullRequest:/65:/SL-Micro/product/repo/Multi-Linux-Manager-Proxy-5.2-x86_64/",
    "slfo_pr_65_retail_uyuni_tools": "http://download.suse.de/ibs/SUSE:/SLFO:/Products:/Multi-Linux-Manager:/5.2:/Packages:/PullRequest:/65:/SL-Micro/product/repo/Multi-Linux-Manager-Retail-Branch-Server-5.2-x86_64/"
  }
}
```

Both families can be passed together, in any order:
`--version 52-micro --slfo-pull-request 370 65`.

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
- `clean_slfo_pull_request_ids()`: Flattens the PullRequest ids of `-s` into a
  de-duplicated list, whether they were given space or comma separated.
- `classify_slfo_pull_requests()`: Asks IBS which project publishes each PullRequest
  id and sorts them into `client_tools` / `mlm_packages`; an unknown id aborts the run.
- `apply_slfo_pull_requests()`: Applies each classified id to the nodes it belongs to,
  replacing the `:ToTest` repos it supersedes.
- `probe_url()`: Cached existence check for an IBS path. Retries on connection errors and on 5xx/429, and returns `None` when IBS stays unreachable.
- `url_exists()`: Same check, but stops the run when IBS is unreachable. Used by the two functions above.

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
  `get_v52_static_and_client_tools(variant)`, which return a
  `(static_repos, dynamic_repos)` pair per variant for stable 5.1 / 5.2.
- `v53_nodes.py`: the helper `get_v53_static_and_client_tools(variant, beta=True)`
  for 5.3 beta placeholders. For **`53-sles-beta`**, fixed ToTest **server** / **proxy**
  image URLs are defined in `v53_uyuni_tools_sles_static_repos_beta`. For
  **`53-micro-beta`** / **`53-sles-beta`**, dynamic client minions include
  **`opensuse156arm_minion`** (SLE-15 aarch64) and **`raspios13_minion`**
  (`MultiLinuxManagerTools-Beta_Debian-13_aarch64`) in
  `v53_nodes_dynamic_client_tools_repos_beta`.

`repository_versions/__init__.py` aggregates everything into the
`nodes_by_version` mapping, whose keys are exactly the strings accepted by
`--version` (`43`, `50-micro`, `50-sles`, `51-micro`, `51-sles`, `52-micro`,
`52-sles`, `53-micro-beta`, `53-sles-beta`) and whose values are
`{"static": ..., "dynamic": ...}` dicts consumed by the main script.

## Error Handling

- If `-v` / `--version` is missing, argparse halts with an error naming the
required argument. Called with no arguments at all, the script prints its help
and exits with 0 instead.
- If no MI IDs are provided via CLI or file, the script will print an error
message and halt execution.
- Invalid MI IDs or missing files will result in appropriate error messages.
- A PullRequest id that no SLFO project publishes halts the run, naming the id and
every path that was probed. An id found in more than one project halts too, since
there is no way to tell which one was meant.

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
