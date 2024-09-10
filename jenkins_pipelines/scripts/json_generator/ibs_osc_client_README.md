# SUSE Maintenance Incident (MI) Embargo Checker

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Usage](#usage)
  - [Initialize `IbsOscClient`](#initialize-ibsoscclient)
  - [Find Maintenance Incidents](#find-maintenance-incidents)
  - [Check if MI is Under Embargo](#check-if-mi-is-under-embargo)
- [Output](#output)
- [Dependencies](#dependencies)
- [License](#license)
- [Notes](#notes)

---

## Overview

This Python script is designed to automate the management of Quality Assurance
Maintenance (QAM) requests for SUSE Linux Enterprise Server (SLES). The script
performs the following tasks:

- **Queries Open Maintenance Incidents (MIs):** Retrieves a list of open MIs
  from the SUSE build service.
- **Checks for Embargo Status:** Determines if an MI is under embargo by
  inspecting its attributes.
- **Retrieves and Processes Information:** Collects and processes relevant
  details about MIs and their associated repositories.

The output is a JSON file, which can be used for further testing in the BV
(Business Validation) testsuite pipeline. The script supports both SUSE Manager
4.3 (SUMA 4.3) and SUSE Manager 5.0 (SUMA 5.0).

## Features

- Queries open maintenance incidents (MIs) from SUSE build service.
- Checks if an MI is under embargo.
- Retrieves and processes relevant information about MIs and their repositories.

## Requirements

- Python 3.11
- `smash_client` library: Ensure you have the `smash_client` module available in
  your environment.

## Usage

### Initialize `IbsOscClient`

```python
from ibs_osc_client import IbsOscClient

client = IbsOscClient()
```

### Find Maintenance Incidents

Find open maintenance incidents in a specified group:

```python
mi_ids = client.find_maintenance_incidents(status='open', group='qam-manager')
```

### Check if MI is Under Embargo

Check if a specific MI is under embargo:

```python
is_under_embargo = client.mi_is_under_embargo(mi_id='123456')
```

## Output

The script outputs a JSON file compatible with the BV testsuite pipeline.

## Dependencies

`smash_client` library

## License

This script is licensed under the [MIT License](https://opensource.org/licenses/MIT).

## Notes

The script uses osc commands for interacting with SUSE build service and may
require these utilities to be installed and properly configured.
Ensure that the environment is set up with the appropriate credentials and
permissions for accessing the SUSE build service.
