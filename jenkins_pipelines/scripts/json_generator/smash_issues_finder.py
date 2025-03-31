import argparse
import json
import logging
from typing import Any
from ibs_osc_client import IbsOscClient

_FORMATS_DEFAULT_FILE_NAMES: dict[str, str] = {
    "json": "smash_issues_list.json",
    "txt": "smash_issues_list.txt"
}

def parse_cli_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="This script consumes the SMASH API 'issues' endpoint and return either a JSON output or a check-list of issues links and summaries"
    )
    # not used as query params
    parser.add_argument("-t", "--smash_token", dest="smash_token", help="SMASH API Token", action='store', required=True)
    parser.add_argument("-a", "--all", dest="all", help="return all available issues", default=False, action='store_true')
    parser.add_argument("-m", "--missing-submissions", dest="missing_subs", default=False, action='store_true',
        help="return only issues missing submissions"
    )
    parser.add_argument("-o", "--output", dest="output_file", default="", help="File in which the results will be saved", action="store")
    parser.add_argument("-f", "--format", dest="output_format", default="json", help="Output file format (JSON default)", action="store",
        choices=["json", "txt"]
    )
    # query params with fixed choices
    parser.add_argument("--reference", dest="reference", help="source to filter the issues by", action="store")
    parser.add_argument("--category", dest="category", help="category to filter issues by", action='store',
        choices=["maintenance", "security"]
    )
    parser.add_argument("--group", dest="group", help="group to filter issues by", action='store',
        choices=["Maintenance", "Kernel Maintenance", "Security"]
    )
    parser.add_argument("--severity", dest="severity", help="severity to filter issues by", action='store',
        choices=["not-set", "low", "moderate", "important", "critical"]
    )
    parser.add_argument("--state", dest="state",help="state to filter issues by", action='store',
        choices= ["new", "ignore", "not-for-us", "analysis", "analyzed", "resolved", "deleted", "merged", "postponed", "revisit"]
    )
    parser.add_argument("--ordering", dest="ordering", help="order results by the given field", action="store",
        choices= ["id", "creation_date", "category"]
    )
    # free text query params
    parser.add_argument("--search", dest="search", help="text to search for in the issue", action='store')
    parser.add_argument("--name", dest="name", help="text to search for in the issue's name", action='store')
    # date query params
    parser.add_argument("--created-after", dest="min_creation_date",
        help="return only issues created after the given date (YYYY-MM-DD format)", action="store"
    )
    parser.add_argument("--created-before", dest="max_creation_date",
        help="return only issues created before the given date (YYYY-MM-DD format)", action="store"
    )

    args: argparse.Namespace = parser.parse_args()
    return args

def issue_to_bsc_link(issue: dict[str, Any]) -> str|None:
        for ref in issue['references']:
            if ref['source'] == 'SUSE Bugzilla':
                bsc_num: str = ref['name'].split("#")[1]
                return f"- [ ] [Bug {bsc_num}]({ref['url']}) - {issue['summary']}\n"
            
        logging.error(f"No Bugzilla reference for issue {issue['name']}- {issue['summary']}\n")
        return None

def store_results(issues: list[dict], output_file: str, output_format: str):
    with open(output_file, 'w', encoding='utf-8') as f:
        if output_format == "json":
            json.dump(issues, f, indent=2, sort_keys=True)
        elif output_format == "txt":
            issues_links: list[str] = [ issue_to_bsc_link(issue) for issue in issues if issue ]
            f.writelines(issues_links)
        else:
            raise ValueError(f"Invalid output format: {output_format} - supported formats {_FORMATS_DEFAULT_FILE_NAMES.keys()}")
    
def cli_args_to_query_params(args: argparse.Namespace) -> dict[str, str|bool]:
    query_params: dict[str, str|bool] = { k: v for k, v in vars(args).items() if v is not None }
    # not query params
    del query_params["smash_token"] # better avoid having this visible in the URL in any case
    del query_params["output_file"]
    del query_params["output_format"]
    del query_params["missing_subs"]

    return query_params

def main():
    args: argparse.Namespace = parse_cli_args()
    ibs_client: IbsOscClient = IbsOscClient(args.smash_token)

    output_format: str = args.output_format
    output_file: str = args.output_file if args.output_file else _FORMATS_DEFAULT_FILE_NAMES[output_format]
    missing_subs: bool = args.missing_subs
    query_params: dict[str, str|bool] = cli_args_to_query_params(args)

    issues: list[dict] = ibs_client.get_issues_list(missing_subs, **query_params)
    store_results(issues, output_file, output_format)

if __name__ == '__main__':
    main()
