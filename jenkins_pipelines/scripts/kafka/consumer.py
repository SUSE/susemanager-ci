
import functools
import json
import logging
import os
import subprocess
import time
import dataclasses

import confluent_kafka
import git
import requests

import producer


logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s [KAFKA CONSUMER]: %(message)s'
)


class APIClients:
    authorization_parameters: tuple = ('manager', os.getenv('JENKINS_API_TOKEN'))

    @staticmethod
    def log_http_requests(request):
        @functools.wraps(request)
        def wrapper(self, *args, **kwargs):
            response = request(self, *args, **kwargs)
            logging.info(f"{request.__name__.upper()} {args[0]}, STATUS: {response.status_code}")
            if response.status_code not in (200, 201):
                logging.error(f"{response.content}")
            return response
        return wrapper

    @log_http_requests
    def get(self, endpoint: str):
        return requests.get(endpoint, auth=self.authorization_parameters, verify=False, timeout=10)

    @log_http_requests
    def post(self, endpoint: str, params=None, data=None):
        if endpoint.startswith('https://hooks.slack.com'):
            return requests.post(endpoint, headers={'Content-Type': 'application/json'}, data=json.dumps(data), timeout=10)
        return requests.post(endpoint, auth=self.authorization_parameters, params=params, verify=False, timeout=10)


@dataclasses.dataclass
class KafkaConsumer:
    consumer = confluent_kafka.Consumer({
        'bootstrap.servers': 'localhost:9092',
        'group.id': 'jenkins_pipelines',
        'auto.offset.reset': 'earliest',
        'enable.auto.commit': False,
        'max.poll.interval.ms': 86400000
    })
    kafka_topic = 'sle_mu_43'
    api_clients = APIClients()

    def __post_init__(self) -> None:
        self.consumer.subscribe([self.kafka_topic])

    @staticmethod
    def pull_latest_susemanager_ci():
        susemanager_ci_repository = git.Repo('/home/appuser/susemanager-ci')
        try:
            susemanager_ci_repository.remotes.origin.pull()
        except git.exc.GitError as stderr:
            logging.warning(f"Error during git pull on susemanager-ci repository: {stderr}")

    @staticmethod
    def generate_custom_repositories(incidents: dict):
        incident_numbers = ','.join(
            str(incident['incident']['incident_id'])
            for incident in incidents['data']
        )
        try:
            subprocess.run(
                [
                    "python3",
                    "susemanager-ci/jenkins_pipelines/scripts/json_generator/maintenance_json_generator.py",
                    "-i", incident_numbers
                ],
                check=True
            )
        except subprocess.CalledProcessError:
            susemanager_ci_latest_commit = git.Repo('/home/appuser/susemanager-ci').head.commit
            logging.error(f"Cannot generate JSON file on the {susemanager_ci_latest_commit} commit of susemanager-ci repository with {incident_numbers} MI IDs")


    def run_jenkins_pipeline(self) -> int | None:
        instances_involved = ['server', 'proxy', 'sle15sp4_client', 'sle15sp4_minion']
        with open('custom_repositories.json', 'r', encoding='utf-8') as custom_repositories:
            custom_repositories_formatted = json.dumps(
                {
                    key: value for key, value in json.load(custom_repositories).items()
                    if key in instances_involved
                },
                indent=4
            )
        build_parameters = {
            'cucumber_gitrepo': 'https://github.com/SUSE/spacewalk.git',
            'cucumber_ref': 'Manager-4.3',
            'tf_file': 'susemanager-ci/terracumber_config/tf_files/SUSEManager-4.3-SLE-update-NUE.tf',
            'sumaform_gitrepo': 'https://github.com/uyuni-project/sumaform.git',
            'sumaform_ref': 'master',
            'sumaform_backend': 'libvirt',
            'terraform_bin': '/usr/bin/terraform',
            'terraform_bin_plugins': '/usr/bin',
            'terraform_parallelism': '',
            'terracumber_gitrepo': 'https://github.com/uyuni-project/terracumber.git',
            'terracumber_ref': 'master',
            'minions_to_run': 'sles15sp4_minion',
            'use_previous_terraform_state': 'false',
            'must_deploy': 'true',
            'must_run_core': 'true',
            'must_sync': 'true',
            'enable_proxy_stages': 'true',
            'enable_client_stages': 'true',
            'must_add_MU_repositories': 'true',
            'must_add_non_MU_repositories': 'true',
            'must_add_keys': 'true',
            'must_create_bootstrap_repos': 'true',
            'must_boot_node': 'true',
            'must_run_tests': 'true',
            'must_run_containerization_tests': 'false',
            'confirm_before_continue': 'false',
            'custom_repositories': custom_repositories_formatted
        }

        request = self.api_clients.post(
            'https://ci.suse.de/job/manager-4.3-qe-sle-update-NUE/buildWithParameters',
            params=build_parameters
        )

        if request.status_code == 201:
            time.sleep(10)  # to avoid "In the quiet period. Expires in <10 sec"
            request = self.api_clients.get(f"{request.headers['Location']}/api/json")
            response = request.json()
            try:
                build_number = response['executable']['number']
                os.rename('custom_repositories.json', f'custom_repositories_{build_number}.json')
                return build_number
            except KeyError:
                logging.error(f"Build number {build_number} was not found in the currently running pipelines, latest output: {response['why']}. Please check if someone else is working on the pipeline.")
                return None
        if request.status_code == 431:
            logging.error(f'Request is too big, perhaps too many RRs to be accepted generated big JSON, run pipeline manually using generated custom_repositories.json in {os.getcwd()}')
        return None

    def pipeline_enabled(self) -> bool:
        return not self.api_clients.get(f'https://ci.suse.de/job/manager-4.3-qe-sle-update-NUE/api/json').json()['color'] == 'disabled'

    def build_status(self, build_number: int) -> str:
        request = self.api_clients.get(f'https://ci.suse.de/job/manager-4.3-qe-sle-update-NUE/{build_number}/api/json')
        response = request.json()
        if response['inProgress']:
            return 'INPROGRESS'
        return response['result']

    def send_message_slack(self, incidents: dict, build_number: int, status: str) -> None:
        mu_requests = [
            f"https://build.suse.de/request/show/{incident['request_id']}"
            for incident in incidents['data']
        ]
        message = {
            'message': f'SLE MU pipeline https://ci.suse.de/job/manager-4.3-qe-sle-update-NUE/{build_number} has status: {status} with the following requests: {mu_requests}'
        }
        self.api_clients.post(
            f"https://hooks.slack.com/triggers/{os.getenv('SLACK_API_URL_APPENDIX')}",
            data=message
        )

    def listen(self) -> None:
        build_number: None | int = None
        try:
            while True:
                time.sleep(300)
                if self.pipeline_enabled() or build_number:
                    if build_number:
                        status = self.build_status(build_number)
                        logging.info(f'Pipeline build {build_number} STATUS: {status}')
                        if status != 'INPROGRESS':
                            self.send_message_slack(incidents, build_number, status)
                            build_number = None
                    else:
                        message = self.consumer.poll(timeout=1.0)
                        if message is None:
                            producer.produce()
                        else:
                            try:
                                incidents = json.loads(message.value().decode('utf-8'))
                            except json.decoder.JSONDecodeError:
                                logging.error(f'Could not decode kafka message: {message.value()}')
                                raise
                            if incidents["recordsFiltered"] > 0:
                                self.pull_latest_susemanager_ci()
                                self.generate_custom_repositories(incidents)
                                build_number = self.run_jenkins_pipeline()
                            self.consumer.commit(message)
                else:
                    logging.info('Pipeline disabled')
        except:
            self.consumer.close()
            raise


if __name__ == '__main__':
    KafkaConsumer().listen()

