# SmashClient

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [Initialize `SmashClient`](#initialize-smashclient)
  - [Get Embargoed Bug IDs](#get-embargoed-bug-ids)
- [Dependencies](#dependencies)
- [License](#license)
- [Notes](#notes)

---

## Overview

The `SmashClient` Python script provides a straightforward interface to interact
with the SUSE Manager's SMASH API to retrieve a list of embargoed bug IDs. This
is useful for managing and tracking software issues that are currently under
embargo, ensuring that you are informed about which bugs and CVEs (Common
Vulnerabilities and Exposures) are restricted and cannot be discussed or
published publicly.

## Features

- Fetches and caches embargoed bug IDs from the SMASH API.
- Returns a set of embargoed bug IDs including associated CVEs.
- Caches results to optimize performance and reduce redundant API calls.

## Requirements

- Python 3.6 or higher
- `requests` library

## Installation

To install the required dependencies, ensure you have `requests` installed:

```bash
pip install requests
```

## Usage

### Initialize SmashClient

First, you need to create an instance of the SmashClient class. This class
handles interaction with the SMASH API and manages caching of embargoed bug IDs.

```python
from your_module_name import SmashClient

client = SmashClient()
```

## Get Embargoed Bug IDs

Once you have an instance of SmashClient, you can fetch the embargoed bug IDs by
calling the get_embargoed_bugs_ids method. This method retrieves the IDs from
the SMASH API and caches them for future use.

```python
embargoed_ids = client.get_embargoed_bugs_ids()
print(embargoed_ids)
```

This method performs the following steps:

1. Checks Cache: If the embargoed IDs are already cached, it returns them
immediately, avoiding unnecessary API calls.
2. Fetches Data: If the cache is empty, it makes a request to the SMASH API to
retrieve the latest embargoed bug IDs.
3. Processes Response: Parses the JSON response to extract bug IDs and CVEs.
4. Updates Cache: Stores the fetched data in the cache for subsequent calls.

## Dependencies

`requests`: A popular Python library for making HTTP requests. It is used here to
handle communication with the SMASH API.

## License

This script is licensed under the [MIT License](https://opensource.org/licenses/MIT).

## Notes

Ensure that the requests library is installed in your environment.
This script relies on the SMASH API being available and responsive. Handle
possible exceptions appropriately in production environments.
Caching helps in reducing the load on the API and speeds up access to the
embargoed IDs, but make sure to handle cache invalidation if the data can change
frequently.
