# susemanager-ci

CI automation for [SUSE Multi-Linux Manager](https://www.suse.com/products/multi-linux-manager/) and [Uyuni](https://www.uyuni-project.org/).

## Contents

- [jenkins_pipelines](jenkins_pipelines): Jenkins pipeline definitions
- [terracumber_config](terracumber_config): Configuration files for terracumber, used by some of the Jenkins pipelines

### Jenkins pipeline definitions

This directory contains the Jenkins pipelines we use in Jenkins.

For details have look at [jenkins_pipelines/README.md](jenkins_pipelines/README.md).

### Configuration files for terracumber

This directory contains the configuration files for terracumber that are used by the test suite and the reference
environment pipelines.

For details have a look at [terracumber_config/README.md](terracumber_config/README.md).

### Mirroring hell at Pull Request testing

Downloading images and packages from download.opensuse.org is not reliable because when you try to do so, you get
redirected to the openSUSE mirror infrastructure. This means:

- You do not always get the same mirror. If you download from Provo, you use the mirror in Provo. If you download from
your workstation, you download from the mirror that is closest to you.
- It takes an uncertain amount of time for an image or package to be available in all the mirrors. Thus, if you try to
download an image or package that was just built in the build service, you won't find that in the mirrors, yet.
- If the image or package has not changed its name, mirrors do not update that file. For example, if you have images
without the build number, which is very convenient to have (aka static links), new builds of the image are not
propagated to the mirrors. The same happens for RPMs, for example, if you remove a project and create it again,
the build number is going to reset and then you can easily have an RPM that has the same build number as before,
meaning the filename is the same and so the mirror will not get updated.
- Sometimes metadata and RPMs do not match. If you hit an "update window time", it could be that the metadata has been
updated on that mirror but it has not finished downloading the RPM.
- Even zypper has some code to manage metalinks, terraform libvirt does not, so if an image is not found close to your
location, it is not found at all.

For all that, we had to skip all the openSUSE mirror infrastructure and provide alternative links.

For Pull Requests we have these alternative URLs:

- http://jenkins-worker-prs.mgr.slc1.suse.org/workspace/suma-prX/repos/: For every environment, there is a list of repos
that are needed for testing a particular Pull Request. This includes the master repo, the pull request repo, the client
repos and some other repos that are also needed. All those repos are synced using the Build Service API, instead of from
download.opensuse.org.
- http://minima-mirror-ci-bv.mgr.slc1.suse.org/pull-request-repositories/dummy/ : This is an empty repo used instead of the update repos. This way,
the build is reproducible.
- http://minima-mirror-ci-bv.mgr.slc1.suse.org/repositories/systemsmanagement:/sumaform:/images:/libvirt/images/. openSUSE
image for testing Pull Requests built with the open build service. This needs to be copied manually.
- http://minima-mirror-ci-bv.mgr.slc1.suse.org/distribution/leap/: oss and non-oss repositories.


## Used image versions

### In the CI test suite

|             | GitHub PR test| Uyuni         | Head         | 5.1          | 5.0           | 4.3          |
|-------------|---------------|---------------|--------------|--------------|---------------|--------------|
| Minion      | Tumbleweed    | Tumbleweed    | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP7   | SLES 15 SP4  |
| SSH minion  | Tumbleweed    | Tumbleweed    | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP7   | SLES 15 SP4  |
| Client      | -             | -             | -            | -            | -             | SLES 15 SP4  |
| RH-like     | Rocky 8       | Rocky 8       | Rocky 8      | Rocky 8      | Rocky 8       | Rocky 8      |
| Deb-like    | Ubuntu 24.04  | Ubuntu 24.04  | Ubuntu 24.04 | Ubuntu 24.04 | Ubuntu 24.04  | Ubuntu 22.04 |
| Virthost    | -             | -             | -            | -            | SLES 15 SP7   | SLES 15 SP4  |
| Buildhost   | Leap 15.6     | SLES 15 SP7   | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP7   | SLES 15 SP4  |
| Terminal    | Leap 15.6     | SLES 15 SP7   | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP7   | SLES 15 SP4  |
| DHCP-DNS    | Leap 15.5     | Leap 15.5     | Leap 15.5    | Leap 15.5    | Leap 15.5     | -            |
| Controller  | Leap 15.6     | Leap 15.6     | Leap 15.6    | Leap 15.6    | Leap 15.6     | Leap 15.6    |
| Server      | Tumbleweed    | Tumbleweed    | SL Micro 6.1 | SL Micro 6.1 | SLE Micro 5.5 | SLES 15 SP4  |
| Proxy       | Tumbleweed    | Tumbleweed    | SL Micro 6.1 | SL Micro 6.1 | SLE Micro 5.5 | SLES 15 SP4  |

### In the full BV test suites

(please refer to the code for now)

### In the mini-BV test suites

|             | 5.2          | 5.1          | 5.0           | 4.3          |
|-------------|--------------|--------------|---------------|--------------|
| Controller  | Leap 15.6    | Leap 15.6    | Leap 15.6     | Leap 15.6    |
| Server      | SL Micro 6.2 | SL Micro 6.1 | SLES 15 SP6   | SLES 15 SP4  |
| Proxy       | SL Micro 6.2 | SL Micro 6.1 | SLES 15 SP6   | SLES 15 SP4  |
| Minion      | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP6   | SLES 15 SP4  |

### In the MI test suites for packages running in containers

|             | 5.2          | 5.1          | 5.0           | 4.3          |
|-------------|--------------|--------------|---------------|--------------|
| Controller  | Leap 15.6    | Leap 15.6    | Leap 15.6     | Leap 15.6    |
| Alt server  | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP6   | SLES 15 SP4  |
| Alt proxy   | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP6   | SLES 15 SP4  |
| Minion      | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP6   | SLES 15 SP4  |

### In the MI test suites for the mgradm and mgrpxy utilities

|             | 5.2          | 5.1          | 5.0           | 4.3          |
|-------------|--------------|--------------|---------------|--------------|
| Controller  | Leap 15.6    | Leap 15.6    | Leap 15.6     | -            |
| Server      | SL Micro 6.2 | SL Micro 6.1 | SLE Micro 5.5 | -            |
| Proxy       | SL Micro 6.2 | SL Micro 6.1 | SLE Micro 5.5 | -            |
| Minion      | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP6   | -            |


## Testing SLES maintenance incidents from inside the SUSE Multi-Linux Manager containers

This Jenkins pipeline architecture automates the validation of Maintenance Incidents (MIs) by building custom server and proxy containers dynamically. By integrating directly with the Internal Build Service (IBS), the CI/CD pipeline alters build configurations on the fly, triggers container rebuilds, and automatically points the deployment stages to the newly generated registries.

### Pipeline Workflow & Architecture

#### 1. Parameterization
The pipeline UI exposes specific parameters to the QE team, allowing them to target exact Maintenance Incidents without hardcoding values:
* `container_project`: The target IBS project (e.g., `Devel:Galaxy:Manager:MUTesting:5.0`).
* `mi_project`: The incident project (e.g., `SUSE:Maintenance:12345`).
* `mi_repo_name`: The specific repository within the incident (e.g., `SUSE_Updates_SLE-Module-Basesystem_15-SP6_x86_64`).

#### 2. The "Build containers" Stage
Located in the shared `pipeline-build-validation.groovy` script, this stage acts as the bridge between Jenkins and IBS.
* **Environment Isolation**: To prevent dependency conflicts on Jenkins worker nodes, the pipeline dynamically creates a Python virtual environment (`venv`) inside the workspace and installs necessary scraping and API libraries.
* **IBS Trigger**: The pipeline invokes `edit.py`, which overrides the targeted IBS project's metadata (`meta`) and configuration (`prjconf`).

#### 3. IBS Rebuild Trigger

IBS (or OBS) is a declarative build system. By altering the `meta` to include the sources of a new Maintenance Incident, in the past we were adjusting the `prjconf` to prefer specific packages, so this feature will stay available on the `edit.py` script, the OBS scheduler automatically detects that the dependencies for the `containerfile` repository have changed. It invalidates the old container binaries and schedules a fresh rebuild incorporating the new MI packages.

#### 4. Dynamic Deployment Routing
Once the script verifies the IBS build is successful, Jenkins intercepts the newly created registry paths. The pipeline dynamically rewrites the deployment variables:
* `custom_project_path`
* `server_container_repository`
* `proxy_container_repository`

By redefining these paths to point to `registry.suse.de/[PROJECT]/containerfile`, the subsequent Terraform and deployment stages will automatically pull and provision the custom-built containers instead of the standard release containers.

Here is an explanation of the package branching concept in OBS/IBS. This is a crucial part of your pipeline's design, and it perfectly explains *why* you are able to manipulate these builds so freely.

I have formatted this as an additional section that you can drop directly into the second README file (under "Pipeline Workflow & Architecture" or as a new standalone section).

### Understanding the IBS "Branching" Architecture

To safely test new Maintenance Incidents (MIs) without risking the stability of official production containers, the pipeline relies on the IBS feature known as **branching** (or linking).

If you look at the `Devel:Galaxy:Manager:MUTesting:5.0` and `5.1` projects, the packages inside them (such as `server-image`, `proxy-squid-image`, `proxy-helm`, etc.) do not host their own independent source code. Instead, they are branched directly from the official release projects (e.g., `SUSE:SLE-15-SP6:Update:Products:Manager50:Update`). If we want to build new packages available on the official release project, we can simply branch the package into our `MUTesting` project.

You can access these projects from:
- https://build.suse.de/project/show/Devel:Galaxy:Manager:MUTesting:5.0
- https://build.suse.de/project/show/Devel:Galaxy:Manager:MUTesting:5.1

Currently we re-build these packages:
5.0:
- init-image (obsolete once 5.0.7 is released)
- proxy-helm
- proxy-httpd-image
- proxy-salt-broker-image
- proxy-squid-image
- proxy-ssh-image
- proxy-tftpd-image
- server-attestation-image
- server-hub-xmlrpc-api-image
- server-image
- server-migration-14-16-image

5.1:
- proxy-helm
- proxy-httpd-image
- proxy-salt-broker-image
- proxy-squid-image
- proxy-ssh-image
- proxy-tftpd-image
- server-attestation-image
- server-hub-xmlrpc-api-image
- server-image
- server-migration-14-16-image
- server-postgresql-image
- server-saline-image

#### What This Means for the Pipeline

Branching creates a powerful, isolated sandbox for the QE pipeline with several key benefits:

1. **Perfect Inheritance (Source of Truth):** A branched package automatically inherits the exact `Dockerfile`, `spec` files, and source code from its parent project. This guarantees that the containers built in the `MUTesting` project are structurally identical to the official SUSE containers. The testing environment perfectly mirrors production.
2. **Complete Isolation:** Because the branched project (`MUTesting`) has its own independent `prjconf` and `meta` configurations, the Jenkins pipeline can aggressively modify them. When the Python script (`edit.py`) injects a new `SUSE:Maintenance:12345` repository or pins a `Prefer` rule, these changes *only* apply to the branched environment. The official release project remains entirely untouched and safe.
3. **Targeted Validation (The "What If" Scenario):** Branching allows the pipeline to create a highly accurate "What If" scenario. By combining the **official source code** (via the branch link) with the **unreleased Maintenance Incident binaries** (injected via the Jenkins pipeline and Python script), the build system produces a custom container. This proves exactly how the official container will behave *after* the MI is officially published, allowing QE to catch regressions before they hit the public registry.
