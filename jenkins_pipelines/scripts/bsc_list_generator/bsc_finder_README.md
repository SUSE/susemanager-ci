# bsc_finder.py

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Output](#output)
- [Logging](#logging)
- [Error Handling](#error-handling)
- [Dependencies](#dependencies)
- [License](#license)
- [Notes](#notes)

---

## Overview

This Python script automates the process of gathering, processing and storing bug reports
consuming Bugzilla REST API.
It requires a valid API key to function.

The script allows users to filter bug reports for SUMA 4.3 and 5.0 products.

## Features

- Fetches and stores bug reports from Bugzilla REST API through a CLI
- Can retrieve the bugs mentioned in SUMA 4.3 and 5.0 release notes

## Requirements

- A valid Bugzilla API key
- osc CLI if you intend to retrieve bug reports from release notes
- Python 3.6 or higher
- `requests` library
- `bugzilla_client` library: Ensure you have the `bugzilla_client` module available in
  your environment.

## Installation

To install the required dependencies, ensure you have `requests` installed:

```bash
pip install requests
```

## Usage

Command-Line Arguments

The script accepts several command-line arguments to control its behavior.

```bash
python bsc_finder.py [options]
```

Options:

1) Required Argument:
    - API Key (-k or --api-key):
        Description: Bugzilla API key (required).
        Usage: -k YOUR_API_KEY or --api-key YOUR_API_KEY

2) Filter Options:
    - All Products (-a or --all):
        Description: Returns results for all supported products, overriding version and cloud flags.
        Usage: -a or --all (flag)
    - Product Version (-p or --product-version):
        Description: Specify the product version of SUMA to run the script for. Options: 4.3 or 5.0. Default is 4.3.
        Usage: -p 5.0 or --product-version 5.0
    - Release notes (-n or --release-notes):
        Description: Retrieves the bug reports mentioned in the latest release notes for the selected SUMA version(s)
        Usage: -n or --release-notes
    - Cloud (-c or --cloud):
        Description: Returns BSCs for SUMA in Public Clouds.
        Usage: -c or --cloud (flag)
    - Status (-s or --status):
        Description: Filters BSCs by status. Options: NEW, CONFIRMED, IN_PROGRESS, RESOLVED.
        Usage: -s NEW or --status NEW
    - Resolution (-r or --resolution):
        Description: Filters issues by resolution. Leave empty for open bugs.
        Usage: -r FIXED or --resolution FIXED

3) Output Options:
    - Output File (-o or --output):
        Description: Specifies the file in which the results will be saved.
        Usage: -o results.txt or --output results.txt
    - Output Format (-f or --format):
        Description: Format for the output file. Options: json, txt. Default is txt.
        Usage: -f json or --format json

Example:

```bash
python bsc_finder.py -k YOUR_API_KEY -p 5.0 -s NEW -c -o results.txt -f txt
```

This command will:

1) Instantiate a new Bugzilla REST API client using your API key
2) Query the API for all the bug reports related to 'SUSE Manager 5.0 in Public Clouds', in status NEW
3) Save the results to a file called 'results.txt', as a .md formatted list of link-summary elements

## Output

The produced output can be one of:
1) a JSON file, containing all the bug reports info
2) a txt file formatted in .md syntax, containing links and a summary for each report.

## Logging

The script includes basic logging for informational messages. To enable logging,
ensure the setup_logging function is called at the beginning of the script. Log
messages will display timestamped INFO-level messages.

## Error Handling

- If no, or an invalid, API key is provided via CLI the script will print an error
message and halt execution.
- Invalid flags values in appropriate error messages.

## Dependencies

`requests`: A popular Python library for making HTTP requests. It is used here to
handle communication with the SMASH API.

## License

This script is licensed under the [MIT License](https://opensource.org/licenses/MIT).

## Notes

Ensure that the requests library is installed in your environment.
This script relies on the Bugzilla REST API being available and responsive and having a valid API key for it.

Handle possible exceptions appropriately in production environments.
Caching helps in reducing the load on the API and speeds up access to the
embargoed IDs, but make sure to handle cache invalidation if the data can change
frequently.
