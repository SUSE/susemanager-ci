import argparse
import json
import logging
from typing import Any

from bugzilla_client import BugzillaClient

_FORMATS_DEFAULT_FILE_NAMES: dict[str, str] = {
    "json": "bsc_list.json",
    "txt": "bsc_list.txt"
}

_PRODUCT_VERSIONS = ["4.3", "5.0"]

def setup_logging():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def parse_cli_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="This script retrieves a list of relevant open BSCs by querying the SUSE Bugzilla REST API and returns either a JSON output or a check-list of BSC links and summaries"
    )
    # required API key
    parser.add_argument("-k", "--api-key", dest="api_key", help="Bugzilla API key", action='store', required=True)
    # filters
    parser.add_argument("-a", "--all", dest="all", default=False, help="Returns results for all supported products (overrides 'version' and 'cloud' flags)", action="store_true")
    parser.add_argument("-p", "--product-version", dest="product_version", help="Product version of SUMA you want to run this script for, the options are 4.3 and 5.0. The default is 4.3 for now",
        choices=_PRODUCT_VERSIONS, default="4.3", action='store'
    )
    parser.add_argument("-c", "--cloud", dest="cloud", default=False, help="Return BSCs for SUMA in Public Clouds", action="store_true")
    parser.add_argument("-s", "--status", dest="status", help="Status to filter BSCs by", action="store",
        choices=["NEW", "CONFIRMED", "IN_PROGRESS", "RESOLVED"]
    )
    parser.add_argument("-r", "--resolution", dest="resolution", help="Resolution to filter issues for (default empty string means open bugs)", action="store")
    # output related flags
    parser.add_argument("-o", "--output", dest="output_file", help="File in which the results will be saved", action="store")
    parser.add_argument("-f", "--format", dest="output_format", default="txt", help="Output file format (txt default)", action="store",
        choices=["json", "txt"]
    )

    args: argparse.Namespace = parser.parse_args()
    return args

def get_suma_product_name(product_version: str, cloud: bool) -> str:
    return f"SUSE Manager {product_version}{' in Public Clouds' if cloud else ''}"

def get_suma_bugzilla_products(all, product_version: str, cloud: bool) -> list[str]:
    if not all:
        return [get_suma_product_name(product_version, cloud)]

    bugzilla_products: list[str] = []
    for version in _PRODUCT_VERSIONS:
        # get both "standard" and cloud product versions
        bugzilla_products.append(get_suma_product_name(version, False))
        bugzilla_products.append(get_suma_product_name(version, True))
    
    return bugzilla_products
    
# return a txt file formatted according to .md syntax, so that it can be used in GitHub cards and the likes
def bugs_to_links_list(products_bugs: dict[str, list[dict]], bugzilla_url: str) -> list[str]:
    lines: list[str] = []

    for product, bugs_list in products_bugs.items():
        lines.append(f"## {product}\n\n")
        for bug in bugs_list:
            id: str = bug['id']
            bug_url: str = f"{bugzilla_url}?id={id}"
            lines.append(f"- [ ] [Bug {id}]({bug_url}) - {bug['priority']} - ({bug['component']}) {bug['summary']}\n")
        lines.append("\n")
    
    return lines

def store_results(products_bugs: dict[str, list[dict]], output_file: str, output_format: str, bugzilla_url: str = ""):
    logging.info(f"Storing results at {output_file} ({output_format} file)")

    with open(output_file, 'w', encoding='utf-8') as f:
        if output_format == "json":
            json.dump(products_bugs, f, indent=2, sort_keys=True)
        elif output_format == "txt":
            issues_links: list[str] = bugs_to_links_list(products_bugs, bugzilla_url)
            f.writelines(issues_links)
        else:
            raise ValueError(f"Invalid output format: {output_format} - supported formats {_FORMATS_DEFAULT_FILE_NAMES.keys()}") 
    
def main():
    setup_logging()
    args: argparse.Namespace = parse_cli_args()
    bugzilla_client: BugzillaClient = BugzillaClient(args.api_key)

    bugzilla_products: list[str] = get_suma_bugzilla_products(args.all, args.product_version, args.cloud)
    product_bugs: dict[str, list[dict[str, Any]]] = {}

    for bugzilla_product in bugzilla_products:
        logging.info(f"Retrieving BSCs for product '{bugzilla_product}'...")
        product_bugs[bugzilla_product] = bugzilla_client.get_bugs(product = bugzilla_product, resolution = args.resolution, status = args.status)
        logging.info("Done")
    
    output_format: str = args.output_format
    output_file: str = args.output_file if args.output_file else _FORMATS_DEFAULT_FILE_NAMES[output_format]

    store_results(product_bugs, output_file, output_format, bugzilla_client.show_bug_url)

if __name__ == '__main__':
    main()
