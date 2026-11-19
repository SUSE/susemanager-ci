#!/usr/bin/env python3
"""Build the hub custom_repositories.json for 5.1 and/or 5.2 from MSQA Jira release tickets.

Per release it reads the Maintenance Incident (MI) ids of the Jira ticket(s), runs
maintenance_json_generator.py for the -sles and -micro variants and merges the two outputs
(merge_hub_repositories.py), so the hub gets split server/proxy keys.

Which MIs go where:
  5.1 file: MIs of every ticket given (the client tools are shared, the 5.1 server/proxy MU is its own)
  5.2 file: MIs of the 5.2 tickets only
With only a 5.2 ticket both files get the same MIs: 5.2 client tools tested on a 5.1 hub without a 5.1 MU.

Jira access is read-only (GET /rest/api/2/issue/<key>), token from the environment, never printed:
  JIRA_API_TOKEN (or JIRA_TOKEN), JIRA_URL (default https://jira.suse.com)

Examples:
  hub_release_repositories.py --jira MSQA-1061 MSQA-1062 --slfo-pr 5.1=372,9672,9674,9675,9676 \\
      --proxy-pr-from 5.1=slmicro61_minion
  hub_release_repositories.py --jira MSQA-1062            # client tools only, both releases
  hub_release_repositories.py --mi-ids 46932 47441 --releases 5.1   # no Jira
  hub_release_repositories.py --jira MSQA-1062 --dry-run  # show the plan, no IBS access
"""
import argparse
import json
import logging
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

from merge_hub_repositories import merge

HERE = Path(__file__).resolve().parent
GENERATOR = HERE / "maintenance_json_generator.py"
DEFAULT_JIRA_URL = "https://jira.suse.com"
RELEASES = ("5.1", "5.2")
MI_RE = re.compile(r"SUSE:/?Maintenance:/?(\d+)")
RELEASE_RE = re.compile(r"Linux Manager\s+(\d+\.\d+)")
KEY_RE = re.compile(r"([A-Z][A-Z0-9]+-\d+)")
# Registry of the 5.1 MU containers (MI project), confirmed on MSQA-1061. 5.2 is not derived.
REGISTRY_HINT = {
    "5.1": "registry.suse.de/suse/sle-15-sp7/update/products/multilinuxmanager51/update/containerfile "
           "(already the default of manager-5.1-qe-hub-testing)",
}


def ticket_key(value: str) -> tuple[str, str | None]:
    """'MSQA-1062', 'MSQA-1062=5.2' or a browse URL -> (key, release override)."""
    value, _, release = value.partition("=")
    match = KEY_RE.search(value)
    if not match:
        raise SystemExit(f"'{value}' is not a Jira key (expected like MSQA-1062 or a /browse/ URL)")
    if release and release not in RELEASES:
        raise SystemExit(f"release override '{release}' must be one of {', '.join(RELEASES)}")
    return match.group(1), release or None


def fetch_issue(key: str, base_url: str, token: str) -> dict:
    url = f"{base_url.rstrip('/')}/rest/api/2/issue/{key}?fields=summary,status,description"
    request = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}", "Accept": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as e:
        hint = {401: "token invalid or expired", 403: "no permission", 404: "ticket not found"}.get(e.code, "")
        raise SystemExit(f"Jira answered HTTP {e.code} for {key} {hint}".strip())
    except urllib.error.URLError as e:
        raise SystemExit(f"Cannot reach Jira at {base_url}: {e.reason}")


def parse_ticket(issue: dict, release_override: str | None = None) -> dict:
    fields = issue["fields"]
    summary = fields.get("summary") or ""
    description = fields.get("description") or ""
    release = release_override
    if not release:
        match = RELEASE_RE.search(summary)
        release = match.group(1) if match else None
    if release not in RELEASES:
        raise SystemExit(
            f"{issue['key']}: cannot tell the release from the summary '{summary}'. "
            f"Pass it as {issue['key']}=5.1 or {issue['key']}=5.2")
    mi_ids: list[str] = []
    for mi in MI_RE.findall(description):
        if mi not in mi_ids:
            mi_ids.append(mi)
    return {
        "key": issue["key"],
        "summary": summary,
        "status": (fields.get("status") or {}).get("name", "?"),
        "release": release,
        "mi_ids": mi_ids,
        "not_ready": description.count("NOT READY"),
    }


def plan_releases(tickets: list[dict]) -> dict[str, list[str]]:
    """release -> MI ids. See the module docstring for the rule."""
    all_mis: list[str] = []
    for ticket in tickets:
        all_mis += [mi for mi in ticket["mi_ids"] if mi not in all_mis]
    plan = {}
    if tickets:
        plan["5.1"] = all_mis
    mis_52: list[str] = []
    for ticket in tickets:
        if ticket["release"] == "5.2":
            mis_52 += [mi for mi in ticket["mi_ids"] if mi not in mis_52]
    if mis_52:
        plan["5.2"] = mis_52
    return plan


def run_generator(version: str, mi_ids: list[str], slfo_prs: list[str], workdir: Path) -> tuple[dict, list[str]]:
    """Runs maintenance_json_generator.py in workdir (it writes custom_repositories.json in cwd)."""
    command = [sys.executable, str(GENERATOR), "--version", version, "--mi_ids", ",".join(mi_ids)]
    if slfo_prs:
        command += ["--slfo-pull-request", *slfo_prs]
    result = subprocess.run(command, cwd=workdir, capture_output=True, text=True, timeout=900)
    output = (result.stdout + result.stderr).splitlines()
    if result.returncode != 0:
        raise SystemExit(f"generator failed for {version} (exit {result.returncode}):\n" + "\n".join(output[-8:]))
    warnings = [line.split(" - ", 2)[-1] for line in output if " - WARNING - " in line]
    with open(workdir / "custom_repositories.json", encoding="utf-8") as f:
        return json.load(f), warnings


def apply_proxy_pr(merged: dict, minion_key: str) -> bool:
    """Copy the slfo_pr_* entries of a minion key to the transactional proxies (SL Micro PR for the proxy OS)."""
    entries = {k: v for k, v in merged.get(minion_key, {}).items() if k.startswith("slfo_pr_")}
    if not entries:
        return False
    if "proxy_transactional" in merged:
        merged["proxy_transactional"].update(entries)
    return True


def per_release(values: list[str] | None, what: str) -> dict[str, list[str]]:
    """['5.1=a,b', '5.2=c'] -> {'5.1': ['a', 'b'], '5.2': ['c']}"""
    result: dict[str, list[str]] = {}
    for value in values or []:
        release, sep, items = value.partition("=")
        if not sep or release not in RELEASES:
            raise SystemExit(f"{what}: expected 5.1=<values> or 5.2=<values>, got '{value}'")
        result.setdefault(release, []).extend(i for i in items.split(",") if i)
    return result


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--jira", nargs="+", metavar="KEY[=REL]", help="one or two MSQA release tickets")
    parser.add_argument("--mi-ids", nargs="+", metavar="ID", help="MI ids instead of Jira (space or comma separated)")
    parser.add_argument("--releases", default="5.1,5.2", help="with --mi-ids: releases to build (default 5.1,5.2)")
    parser.add_argument("--slfo-pr", action="append", metavar="REL=ID,ID", help="SLFO PullRequest ids for a release")
    parser.add_argument("--proxy-pr-from", action="append", metavar="REL=MINION_KEY",
                        help="also put the slfo_pr_* entries of this minion key (e.g. slmicro61_minion) on the micro proxy")
    parser.add_argument("--outdir", default="hub-custom-repositories", help="output directory (default %(default)s)")
    parser.add_argument("--dry-run", action="store_true", help="read Jira and print the plan; no IBS access, no files")
    args = parser.parse_args(argv)
    if bool(args.jira) == bool(args.mi_ids):
        parser.error("give either --jira or --mi-ids")
    if args.jira and len(args.jira) > 2:
        parser.error("at most two tickets (a 5.1 and a 5.2 one)")
    return args


def load_plan(args) -> tuple[dict[str, list[str]], list[dict]]:
    if args.mi_ids:
        mis = [mi for value in args.mi_ids for mi in value.split(",") if mi]
        releases = [r.strip() for r in args.releases.split(",")]
        if any(r not in RELEASES for r in releases):
            raise SystemExit(f"--releases must be a list of {', '.join(RELEASES)}")
        return {r: mis for r in releases}, []
    token = os.environ.get("JIRA_API_TOKEN") or os.environ.get("JIRA_TOKEN")
    if not token:
        raise SystemExit("JIRA_API_TOKEN is not set (restart the container after adding it to docker-compose.yml)")
    base_url = os.environ.get("JIRA_URL") or DEFAULT_JIRA_URL
    tickets = []
    for value in args.jira:
        key, override = ticket_key(value)
        tickets.append(parse_ticket(fetch_issue(key, base_url, token), override))
    return plan_releases(tickets), tickets


def main(argv=None) -> int:
    args = parse_args(argv)
    plan, tickets = load_plan(args)
    slfo = per_release(args.slfo_pr, "--slfo-pr")
    proxy_from = {r: v[0] for r, v in per_release(args.proxy_pr_from, "--proxy-pr-from").items()}

    for ticket in tickets:
        print(f"{ticket['key']}  {ticket['summary']}  [{ticket['status']}]  release {ticket['release']}")
        print(f"  MIs: {' '.join(ticket['mi_ids']) or 'none found'}")
        if ticket["not_ready"]:
            print(f"  WARNING: {ticket['not_ready']} entries still say NOT READY, repositories may not be published")
    for release, mis in plan.items():
        print(f"{release}: {len(mis)} MIs, SLFO PRs {','.join(slfo.get(release, [])) or '-'}")
    if args.dry_run:
        return 0
    if not plan or not any(plan.values()):
        raise SystemExit("no MI ids found, nothing to generate")

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    release_digits = {"5.1": "51", "5.2": "52"}
    for release, mis in plan.items():
        with tempfile.TemporaryDirectory(prefix="hub-repos-") as tmp:
            outputs = {}
            for variant in ("sles", "micro"):
                outputs[variant], warnings = run_generator(
                    f"{release_digits[release]}-{variant}", mis, slfo.get(release, []), Path(tmp))
                for warning in warnings:
                    print(f"  {release}-{variant}: {warning}")
        merged = merge(outputs["sles"], outputs["micro"])
        if release in proxy_from and not apply_proxy_pr(merged, proxy_from[release]):
            print(f"  WARNING: no slfo_pr_* entry on {proxy_from[release]}, proxy left unchanged")
        target = outdir / f"hub-{release}-custom_repositories.json"
        with open(target, "w", encoding="utf-8") as f:
            json.dump(merged, f, indent=2, sort_keys=True)
        print(f"{release}: {len(merged)} keys -> {target}")
        print(f"  paste into custom_repositories of manager-{release}-qe-hub-testing, mi_ids empty")
        if any(t["release"] == release for t in tickets) and release in REGISTRY_HINT:
            print(f"  containers: {REGISTRY_HINT[release]}")
    return 0


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    sys.exit(main())
