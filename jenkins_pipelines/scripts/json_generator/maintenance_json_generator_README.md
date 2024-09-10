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
BV (Business Validation) testsuite pipeline for further testing. It supports
both SUSE Manager 4.3 (SUMA 4.3) and SUSE Manager 5.0 (SUMA 5.0).

The script allows users to input Maintenance Incident (MI) IDs and generates the
appropriate repository information for SUMA 4.3 or 5.0 nodes (servers, proxies,
and clients). It retrieves the necessary information for these nodes and their
associated repositories.

## Features

- Support for SUSE Manager 4.3 and 5.0: The script allows users to specify which
version of SUSE Manager they are working with.
- Flexible MI ID Input: MI IDs can be provided via CLI arguments or by reading
from a file.
- Custom Repository Generation: Outputs a JSON file containing repository
information for the SUSE Manager BV testsuite pipeline.
- Embargo Checks: The script has an option to reject Maintenance Incidents (MIs)
that are under embargo.

## Usage
Command-Line Arguments
The script accepts several command-line arguments to control its behavior.

```bash
python script.py [options]
```

Options:

`-v`, `--version`: Specifies the SUSE Manager version. Options are `43` for SUSE
Manager 4.3 and `50` for SUSE Manager 5.0. Default is 43.
`-i`, `--mi_ids`: A space-separated list of MI IDs.
`-f`, `--file`: Path to a file containing MI IDs, each on a new line.
`-e`, `--no_embargo`: Reject any MIs that are currently under embargo.

Example:

```bash
python script.py --version 50 --mi_ids 1234 5678 --file mi_ids.txt --no_embargo
```
This command will:

1. Run the script for SUSE Manager 5.0 (`--version 50`).
2. Use MI IDs 1234 and 5678 along with any additional MI IDs from the file
mi_ids.txt.
3. Reject any MIs that are under embargo (`--no_embargo`).

## Output
The script generates a file named custom_repositories.json, which contains the
repository data for the provided MI IDs.

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
The script contains two main dictionaries for SUSE Manager client tools
repositories:

- `v43_client_tools`: Contains repository data for SUMA 4.3 client tools.
- `v50_client_tools_beta`: Contains repository data for SUMA 5.0 beta client tools.
- `merged_client_tools`: Merges the 4.3 and 5.0 beta client tools into a single
dictionary.

It also defines two dictionaries for SUSE Manager server and proxy
repositories:

- `v43_nodes`: Includes repository data for SUMA 4.3 server and proxy nodes.
- `v50_nodes`: Includes repository data for SUMA 5.0 server and proxy nodes.

The final repository information is stored in the nodes_by_version dictionary,
which maps SUMA version numbers (`43`, `50`) to the corresponding repository data.

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
