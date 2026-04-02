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
| DHCP-DNS    | Leap 15.6     | Leap 15.6     | Leap 15.6    | Leap 15.6    | Leap 15.6     | -            |
| Controller  | Leap 15.6     | Leap 15.6     | Leap 15.6    | Leap 15.6    | Leap 15.6     | Leap 15.6    |
| Server      | Tumbleweed    | Tumbleweed    | SL Micro 6.1 | SL Micro 6.1 | SLE Micro 5.5 | SLES 15 SP4  |
| Proxy       | Tumbleweed    | Tumbleweed    | SL Micro 6.1 | SL Micro 6.1 | SLE Micro 5.5 | SLES 15 SP4  |

### In the full BV test suites

(please refer to the code for now)

### In the mini BV test suites

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
| Server      | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP6   | SLES 15 SP4  |
| Proxy       | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP6   | SLES 15 SP4  |
| Minion      | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP6   | SLES 15 SP4  |

### In the MI test suites for the mgradm and mgrpxy utilities

|             | 5.2          | 5.1          | 5.0           | 4.3          |
|-------------|--------------|--------------|---------------|--------------|
| Controller  | Leap 15.6    | Leap 15.6    | Leap 15.6     | -            |
| Server      | SL Micro 6.2 | SL Micro 6.1 | SLE Micro 5.5 | -            |
| Proxy       | SL Micro 6.2 | SL Micro 6.1 | SLE Micro 5.5 | -            |
| Minion      | SLES 15 SP7  | SLES 15 SP7  | SLES 15 SP6   | -            |


## ## Testing SLES Maintenance Incidents

### Overview

The pipeline integrates directly with the **Internal Build Service (IBS)** to alter configurations on the fly, trigger container rebuilds, and point deployment stages to newly generated registries. This ensures that unreleased patches are validated in a production-like environment before public release.

---

### Test Strategy

The core objective is to validate the impact of a single MI on the SUSE Multi-Linux Manager ecosystem.

#### 1. The Principle of Isolation

The pipeline adheres to a **Single-MI Validation** rule to ensure results are untainted.

* **The "Why":** MIs are released independently. Testing multiple MIs simultaneously creates "co-dependency" risks where a test passes only because of a specific combination that may never exist in production.
* **The Scope:** We replicate the current released state plus *only* the specific unreleased packages from the target MI.

#### 2. Targeted Package Updates

Containers are rebuilt against the MI project to observe the resulting package set:

* **Repository Configuration:** Uses `edit.py` to swap existing `SUSE:Maintenance:*` paths in IBS metadata with the target MI.
* **Package Selection:** The resolver pulls MI packages automatically unless explicit `Prefer` rules are required in the project metadata.
* **Structural Integrity:** Validates that the update doesn't break dependencies, service startup, or core functionality.

#### 3. Validation Goal

At the end of the build, we have a **"What-If" snapshot**. This provides the **qam-manager** team with data-backed approval for SLES maintenance packages before they go live.

---

### Pipeline Workflow & Architecture

#### 1. Parameterization

The UI allows the QE team to target exact incidents without code changes:

* **`container_project`**: The target IBS project (e.g., `Devel:Galaxy:Manager:MUTesting:5.0`).
* **`mi_project`**: The incident project (e.g., `SUSE:Maintenance:12345`).

#### 2. The "Build Containers" Stage

Acting as the bridge between Jenkins and IBS, this stage handles:

* **Environment Isolation:** Creates a Python `venv` inside the workspace for API libraries.
* **IBS Metadata Injection:** Invokes `edit.py` to override the project `meta`.
  * **Important**: When injecting MIs, we must use the specific codestream of the MI project. If multiple exist, they must be included in reverse alphabetical order.
* **Wipe before Rebuild:** A `wipe` operation clears old artifacts to ensure a clean build.
  * *Manual command:* `osc wipebinaries --all <container_project>`

  
#### 3. IBS Rebuild Trigger

Once the `meta` is altered, the OBS scheduler detects dependency changes, invalidates old binaries, and schedules a fresh rebuild.

* **Manual Verification:**
    ```bash
    # Check specific package build info
    osc buildinfo -d <container_project> <package_name> <repository_name> x86_64
    
    # Filter for specific MI packages
    osc buildinfo -d <container_project> server-image containerfile x86_64 | grep bdep | grep <package_name>
    
    ```

#### 4. Dynamic Deployment Routing

Upon a successful build, Jenkins intercepts the new registry paths and rewrites the following variables to point to `registry.suse.de/[PROJECT]/containerfile`:

* `custom_project_path`
* `server_container_repository`
* `proxy_container_repository`

---

### Understanding the IBS "Branching" Architecture

To safely test without risking production stability, the pipeline utilizes **IBS Branching**. Projects like `MUTesting:5.0` do not host independent source code; they are branched from official release projects.

#### Current Packages Rebuilt

| Category | 5.0 Packages | 5.1 Packages |
| --- | --- | --- |
| **Server** | `server-image`, `server-attestation-image`, `server-hub-xmlrpc-api-image`, `server-migration-14-16-image`, `init-image` | `server-image`, `server-attestation-image`, `server-hub-xmlrpc-api-image`, `server-migration-14-16-image`, `server-postgresql-image`, `server-saline-image` |
| **Proxy** | `proxy-helm`, `proxy-httpd`, `proxy-salt-broker`, `proxy-squid`, `proxy-ssh`, `proxy-tftpd` | `proxy-helm`, `proxy-httpd`, `proxy-salt-broker`, `proxy-squid`, `proxy-ssh`, `proxy-tftpd` |

#### Key Benefits of this Architecture

1. **Perfect Inheritance:** Branched packages inherit the exact `Dockerfile` and `spec` files from the parent, ensuring the test environment perfectly mirrors production.
2. **Complete Isolation:** Modifications made by `edit.py` (like injecting an MI) *only* affect the branched `MUTesting` environment.
3. **Targeted Validation:** By combining official source code with unreleased binaries, we catch regressions before they reach the public registry.
