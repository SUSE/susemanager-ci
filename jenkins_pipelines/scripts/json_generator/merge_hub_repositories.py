#!/usr/bin/env python3
"""Merge the sles and micro maintenance_json_generator.py outputs into one hub custom_repositories.json.

server/proxy mean different repositories per variant, so they are relabelled
*_non_transactional (sles run) and *_transactional (micro run). Every other key is shared.
"""
import argparse
import json
import logging

SPLIT_KEYS = ("server", "proxy")


def merge(sles: dict, micro: dict) -> dict:
    merged = {k: v for k, v in sles.items() if k not in SPLIT_KEYS}
    for key, repos in micro.items():
        if key in SPLIT_KEYS:
            continue
        if key in merged and merged[key] != repos:
            logging.warning(f"{key} differs between the sles and micro runs, keeping the micro one")
        merged[key] = repos
    for key in SPLIT_KEYS:
        if key in sles:
            merged[f"{key}_non_transactional"] = sles[key]
        if key in micro:
            merged[f"{key}_transactional"] = micro[key]
            # ponytail: the flat key is only read by the testsuite (primary proxy custom channel) and assumes
            # the primary instances are micro; add a --primary-variant option if a topology puts sles first
            merged[key] = micro[key]
    return merged


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sles", required=True, help="generator output for the sles variant")
    parser.add_argument("--micro", required=True, help="generator output for the micro variant")
    parser.add_argument("--output", required=True)
    args = parser.parse_args(argv)

    with open(args.sles, encoding="utf-8") as f:
        sles = json.load(f)
    with open(args.micro, encoding="utf-8") as f:
        micro = json.load(f)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(merge(sles, micro), f, indent=2, sort_keys=True)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    main()
