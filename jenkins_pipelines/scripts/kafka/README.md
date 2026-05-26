# Kafka automation concept

Messaging system to automate manual tasks with SUSE internal services via API.

## Requirements

### Host

Tested on the SLE 15 SP6 host deployed in a fully trusted environment with the following packages installed:
* `docker` package from [Virtualization repository](https://download.opensuse.org/repositories/Virtualization:/containers/15.6/).

### Variables

The following environment variables need to be exported on the container's host:
* [`JENKINS_API_TOKEN`](https://ci.suse.de/user/manager/configure).
* [`SLACK_API_URL_APPENDIX`](https://app.slack.com/client/T02863RC2AC/platform) (_in the form of `"T02863RC2AC/<alphanumeric data>/<alphanumeric data>"`_).

### Networking

The following websites needs to be resolvable within the docker container network:
* `https://smelt.suse.de`
* `https://hooks.slack.com`
* `https://ci.suse.de`
* `https://github.com`

## Usage

### Building and Running

Being in the `susemanager-ci/jenkins_pipelines/scripts/kafka` catalog, build `kafka` container:

```bash
docker build . --tag "kafka"
```

With exported `JENKINS_API_TOKEN` and `SLACK_API_URL_APPENDIX`, run `kafka` container:

```bash
docker run --name "kafka" --env JENKINS_API_TOKEN=${JENKINS_API_TOKEN} --env SLACK_API_URL_APPENDIX=${SLACK_API_URL_APPENDIX} --network "host" kafka
```

### Topics Available

* `sle_mu_43`:
  1. Pulls the latest [MU requests](https://smelt.suse.de/overview/) to be accepted and generates json based on the latest [susemanager-ci](https://github.com/SUSE/susemanager-ci/tree/master) scripts.
  2. Start a [new manager-4.3-qe-sle-update pipeline](https://ci.suse.de/view/Manager/view/Manager-4.3/job/manager-4.3-qe-sle-update-NUE/) and monitors the status running.
  3. Send message to the dedicated Slack channel [andy-test](https://app.slack.com/client/T02863RC2AC/C033KJKDF9V) informing about the status.

  ⚠️ _Producing script should be integrated to the https://smelt.suse.de site, at the moment it is sending requests from container_.

### Debugging

Alongside kafka logging, built-in logger should capture API requests to external services with the corresponding return codes and return messages:

```bash
docker logs "kafka"
```

## Additional resources

* [SLE MU pipeline automation concept](https://github.com/SUSE/spacewalk/issues/24966).
* [SLE Maintenance updates document](https://confluence.suse.com/display/SUSEMANAGER/QE+SLE+Maintenance+Updates).

