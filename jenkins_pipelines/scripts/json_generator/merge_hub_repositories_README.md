# merge_hub_repositories.py

Merges two `maintenance_json_generator.py` outputs (one `-sles` run, one `-micro` run) into the
single `custom_repositories.json` a hub environment needs.

## Why it exists

The generator produces repos for one variant per run. In `server` and `proxy` the same key means
different repositories depending on the variant: SLES hosts and SL Micro (transactional) hosts do not
install the same packages. A hub topology has both (5.1: `hub`, `prh1`, `prh2`, `proxy`, `proxy3`
on micro; `proxy2` on SLES), so one run cannot describe it.

`prepare_tfvars.py` already understands split keys and maps them to the `*_ADDITIONAL_REPOS_*`
tfvars. This script produces them.

## Usage

```bash
python3 maintenance_json_generator.py --version 51-sles  --mi_ids 12345 12346
mv custom_repositories.json sles.json
python3 maintenance_json_generator.py --version 51-micro --mi_ids 12345 12346
mv custom_repositories.json micro.json

python3 merge_hub_repositories.py --sles sles.json --micro micro.json --output hub.json
```

Use the same MI ids (and `--slfo-pull-request` ids) for both runs. Rename the output of the first run
before the second one, since both write `custom_repositories.json` in the current directory.

| Option | Meaning |
|---|---|
| `--sles` | generator output of the `*-sles` run |
| `--micro` | generator output of the `*-micro` run |
| `--output` | merged file |

Needs Python 3.10 or newer (call plain `python3`). No network access: it only reads the two files.

## Merge rules

| Key | Result |
|---|---|
| `server`, `proxy` | relabelled `server_non_transactional` / `proxy_non_transactional` (from sles) and `server_transactional` / `proxy_transactional` (from micro) |
| flat `server`, `proxy` | **not written**: only the split keys exist, so no key hides which variant it holds |
| any other key (`*_minion`, ...) | shared: taken from sles, then micro; if both exist and differ, a `WARNING` is logged and **micro wins** |
| key in one run only | kept as is |

A split key present in only one run is only written for that run; the other variant gets nothing
for it. The flat key is then absent if the micro run has no `server`/`proxy`.

## Example

```text
sles.json   {"server": {"46386": "S"}, "proxy": {"46393": "SP"}, "ubuntu2404_minion": {"46374": "U"}}
micro.json  {"server": {"slfo_pr_65_server_uyuni_tools": "M"}, "proxy": {"slmicro6_client_tools": "MP"}, "ubuntu2404_minion": {"46374": "U"}}

hub.json    server_non_transactional = S      server_transactional = M
            proxy_non_transactional  = SP     proxy_transactional  = MP
            ubuntu2404_minion        = U      (identical in both runs, kept once)
```

## Where the result goes

Paste `hub.json` into the `custom_repositories` parameter of `manager-<ver>-qe-hub-testing`, with
`mi_ids` empty (a non-empty `mi_ids` regenerates the file and overwrites it). The full procedure is in
`jenkins_pipelines/environments/build-validation/HUB_TESTING.md`.

No pipeline calls this script yet.

## Checks

Look at the output keys before using it; a `WARNING ... differs between the sles and micro runs` line
means a minion got different repos in the two runs.

```bash
python3 -c 'import json; print(sorted(json.load(open("hub.json"))))'
```

Unit tests: `jenkins_pipelines/scripts/tests/test_merge_hub_repositories.py`.

## Known limit

There is no flat `server` / `proxy` key. `prepare_tfvars.py` does not need it (split keys replace it), but
the testsuite falls back to the flat `proxy` key in `custom_repositories_for` (`features/support/proxy_flavour.rb`)
when no `proxy_<flavour>` key exists. On a hub JSON that lookup returns nothing, so check that the proxy
custom channel scenarios still find their repositories.
