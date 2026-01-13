import argparse
from ibs_osc_client import IbsOscClient

OUTPUT_FILE_NAME: str = 'bugzilla_tickets_list.txt'

def parse_cli_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="This script retrieves a list of relevant open BSC"
    )
    # not used as query params
    parser.add_argument("-t", "--smash_token", dest="smash_token", help="SMASH API Token", action='store', required=True)
    parser.add_argument("-a", "--all", dest="all", help="return all available issues", action='store_true')
    parser.add_argument("-m", "--missing-submissions", dest="missing_subs", default=False, action='store_true',
        help="return only issues missing submissions"
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

def store_results(issues: list[str], output_file: str = OUTPUT_FILE_NAME):
    with open(output_file, 'w', encoding='utf-8') as f:
        f.writelines(issues)

def cli_args_to_query_params(args: argparse.Namespace) -> dict[str, str|bool]:
    query_params: dict[str, str|bool] = { k: v for k, v in vars(args).items() if v is not None }
    del query_params["smash_token"] # better avoid having this visible in the URL
    del query_params["missing_subs"] # not a query param

    return query_params

def main():
    args: argparse.Namespace = parse_cli_args()
    ibs_client: IbsOscClient = IbsOscClient(args.smash_token)

    missing_subs: bool = args.missing_subs
    query_params: dict[str, str|bool] = cli_args_to_query_params(args)

    issues: list[str] = ibs_client.get_bsc_links_list(missing_subs, **query_params)
    store_results(issues)


if __name__ == '__main__':
    main()