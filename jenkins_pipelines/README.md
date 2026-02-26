# jenkins_pipelines

This directory contains the Jenkins pipeline definitions used to deploy and test SUSE Multi-Linux Manager and Uyuni environments.

## Contents

- [environments](environments/): Job definitions for all testsuite, Build Validation, and reference environment pipelines
- [manager_prs](manager_prs/): Manager PR checks
- [uyuni_prs](uyuni_prs/): Uyuni PR checks
- [scripts](scripts/): Helper scripts used by the pipelines

## Directory structure

```
jenkins_pipelines/
├── data/                        # Non MU channels tasks description
├── environments/
│   ├── build-validation/        # One job file per BV environment (parameter files)
│   ├── common/                  # Shared Groovy pipeline logic
│   ├── personal/                # Personal pipeline job definitions
│   ├── salt-shaker/             # One job file per Salt-shaker job (parameter files)
│   ├── sle-maintenance-update/  # One job file per SLE Maintenance environment (parameter files)
│   └── manager* | uyuni*        # One job file per other environment (parameter files) mainly CIs
├── manager_prs/                 # SUMA/MLM PRs project related configurations (not used)
├── scripts/
│   ├── edit_bci_project/        # Edit BCI project to build container images (SLE Mi BCI 5.1 and 5.0 pipeline)
│   ├── json_generator/          # JSON generation scripts
│   ├── test_review_summary/     # Test review summary script 
│   ├── tests/                   # Unit tests for the scripts
│   └── tf_vars_generator/
│       └── prepare_tfvars.py    # tfvars assembly script (see below)
└── uyuni_prs/                   # Uyuni PRs project related configurations (not used)
```

### `environments/build-validation/`

Each file in this directory is a **job definition** for one BV environment (e.g. `manager-5.0-micro-qe-build-validation`). These files are thin wrappers: they define the job-specific parameters and delegate all pipeline logic to the shared `common/pipeline-build-validation.groovy`.

### `environments/common/`

Contains the shared Groovy pipeline scripts reused across multiple jobs:

| File | Purpose                              |
|---|--------------------------------------|
| `pipeline-build-validation.groovy` | Standard BV pipeline (deploy + test) |
| `pipeline-build-validation-aws.groovy` | BV pipeline for AWS deployments      |
| `pipeline-build-validation-cleanup.groovy` | Standalone cleanup pipeline for BV   |
| `pipeline-personal.groovy` | Personal CI pipeline                 |
| `pipeline.groovy` | Standard testsuite pipeline (CI)     |
| `pipeline-pull-request.groovy` | Pull request testing pipeline        |
| `pipeline-reference.groovy` / `pipeline-reference-new.groovy` | Reference environment pipelines      |
| `pipeline-salt-shaker.groovy` | Salt-shaker pipeline                 |

## Build Validation pipeline

### How it works

The BV pipeline assembles a `terraform.tfvars` file at runtime by merging several sources, then passes it to terracumber for deployment. The assembly is handled by `prepare_tfvars.py` (see [tfvars generator](#tfvars-generator) below).

The pipeline supports two deployment modes, selected by which parameter is provided:

**Standard BV** (`deployment_tfvars` parameter): loads a static per-environment tfvars file from `terracumber_config/tf_files/tfvars/build-validation-tfvars/`, optionally strips minions not listed in `minions_to_run`, then merges location variables and injects dynamic values from Jenkins.

**Personal BV** (`environment` parameter) — *work in progress*: a minimalist sandbox (controller, server, proxy, and up to 7 minions) that lets a developer test a specific submission or minion change in isolation, without impacting shared BV environments. Unlike *Sandbox BV* (which is used for BV pipeline development), Personal BV is intended for testing submission content. Personal BV reuses the same hardware as Personal CI; the two are **mutually exclusive** — only one can be deployed at a time on the same hardware.

### Key parameters

| Parameter | Description |
|---|---|
| `deployment_tfvars` | Path to the static `.tfvars` file for the environment (standard BV) |
| `minions_to_run` | Space-separated list of resource keys to keep; all others are stripped from the tfvars |
| `environment` | Personal environment identifier (personal BV, mutually exclusive with `deployment_tfvars`) |
| `sumaform_gitrepo` / `sumaform_ref` | Sumaform repository and branch to clone |
| `must_deploy` | Whether to run the deploy stage |
| `use_previous_terraform_state` | Restore Terraform state from the previous build's artifacts |
| `custom_repositories` | JSON string with additional package repositories to inject |
| `mi_ids` | Maintenance Incident IDs; triggers JSON generation for MI testing |
| `server_container_repository` / `proxy_container_repository` | Container image sources injected into tfvars |
| `cucumber_gitrepo` / `cucumber_ref` | Cucumber testsuite repository and branch |

### tfvars generator

`scripts/tf_vars_generator/prepare_tfvars.py` assembles the final `terraform.tfvars` consumed by terracumber. It is called during the Deploy stage before `tofu apply`.

**What it does:**

- Merges the static per-environment tfvars file with `tfvars/location.tfvars` (site-specific network settings)
- Injects dynamic values from Jenkins at runtime (container repositories, image tags, Cucumber branch, product version, etc.) via `--inject KEY=VALUE` flags
- In standard BV mode: strips minions not present in `minions_to_run` via `--clean --keep-resources` to allow partial deployments without editing the tfvars file
- In personal BV mode: constructs a minimalist configuration from a personal environment reference, selecting only the minions the user wants to test against (*work in progress*)

**Invocation in the pipeline (standard BV, simplified):**

```bash
python3 scripts/tf_vars_generator/prepare_tfvars.py \
  --output terraform.tfvars \
  --inject SERVER_CONTAINER_REPOSITORY=<value> \
  --inject CUCUMBER_BRANCH=<value> \
  --merge-files deployment.tfvars location.tfvars \
  --clean --keep-resources sles15sp7_minion rocky8_minion ...
```

The output file is then passed to terracumber via `--tf_configuration_files`.

For the full picture of how the tfvars files are structured and how they map to the sumaform `build_validation` module, see [terracumber_config/README.md](../terracumber_config/README.md).