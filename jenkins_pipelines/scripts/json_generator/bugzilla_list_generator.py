import argparse
from smash_client import Categories, State
from ibs_osc_client import IbsOscClient

OUTPUT_FILE_NAME: str = 'bugzilla_tickets_list.txt'

def parse_cli_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="This script retrieves a list of relevant open BSC"
    )
    parser.add_argument("-t", "--smash_token", dest="smash_token", help="SMASH API Token", action='store', required=True)

    args: argparse.Namespace = parser.parse_args()
    return args

def store_results(issues: list[str], output_file: str = OUTPUT_FILE_NAME):
    with open(output_file, 'w', encoding='utf-8') as f:
        f.writelines(issues)


def main():
    args: argparse.Namespace = parse_cli_args()
    ibs_client: IbsOscClient = IbsOscClient(args.smash_token)

    issues: list[str] = ibs_client.get_bsc_links_list(owner = "jmodak@suse.com", category = Categories.MAINTENANCE, state= State.NEW, name = "bnc")
    store_results(issues)


if __name__ == '__main__':
    main()