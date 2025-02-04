import argparse
from smash_client import SmashClient, Categories

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
    smash_client: SmashClient = SmashClient(args.smash_token)

    issues: list[str] = smash_client.get_bsc_links_list(category = Categories.MAINTENANCE, name = "bnc")
    store_results(issues)


if __name__ == '__main__':
    main()