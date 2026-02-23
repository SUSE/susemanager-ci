# terracumber_config

This directory contains the configuration files for terracumber used to create environments and run Cucumber (except for reference environments).

## Directory structure

```
terracumber_config/
├── tf_files/
│   ├── common/                        
│   ├── personal/                      # Personal pipeline Terraform files
│   ├── salt-shaker/                   # Salt-shaker specific Terraform files
│   ├── templates/                     # Terraform wrapper templates for Build Validation
│   │   ├── build-validation-single-provider.tf
│   │   ├── build-validation-multi-providers.tf
│   │   └── PR-testing.tf
│   ├── tfvars/
│   │   ├── build-validation-tfvars/   # Per-environment tfvars for BV pipelines
│   │   │   ├── mlm51_micro_build_validation_nue.tfvars
│   │   │   ├── suma50_micro_build_validation_nue.tfvars
│   │   │   ├── suma50_micro_build_validation_slc.tfvars
│   │   │   └── ...
│   │   ├── sle-update-tfvars/         # Per-environment tfvars for SLE update pipelines
│   │   │   └── ...
│   │   ├── PR-tfvars/                 # tfvars for PR testing
│   │   └── location.tfvars            # Location-specific network/infrastructure values
│   └── variables/
│       ├── build-validation-variables.tf
│       └── PR-testing-variables.tf
└── mail_templates/                    # Email templates for pipeline notifications
```

## Build Validation pipeline architecture

The Build Validation (BV) pipeline uses a **dynamic, modular Terraform architecture** to reduce code duplication and simplify maintenance. Rather than maintaining one `main.tf` per environment (which led to near-identical files drifting apart), the architecture separates *what to deploy* (the sumaform module in [sumaform](https://github.com/uyuni-project/sumaform)) from *where and how to deploy it* (the tfvars files here).

### How it works

The sumaform `modules/build_validation/main.tf` uses Terraform's `count` and `lookup` to conditionally create each minion: if a key is present in the `ENVIRONMENT_CONFIGURATION` map in the tfvars file, the module is created (`count = 1`); if it is absent, it is skipped (`count = 0`). This means a single `main.tf` serves all BV environments — only the tfvars file changes between deployments.

To deploy a given environment, the Jenkins pipeline uses `prepare_tfvars.py` to assemble the final `terraform.tfvars` from multiple sources (see [tfvars generation](#tfvars-generation) below), then passes it to terracumber.

### Terraform wrapper templates

Because sumaform uses the [libvirt Terraform provider](https://github.com/dmacvicar/terraform-provider-libvirt), each environment must declare provider aliases that map to one or more hypervisors. Two wrapper templates handle the two deployment scenarios:

**`build-validation-single-provider.tf`** — for sites with a single hypervisor (e.g. Nuremberg/Prague). All provider aliases point to the same host.

**`build-validation-multi-providers.tf`** — for sites with multiple hypervisors for the same architecture (e.g. SLC/backup). Each provider alias points to a separate hypervisor, allowing VMs to be distributed across machines. The wrapper declares one provider block per hypervisor and links them to the sumaform module via aliases.

The wrapper templates call the sumaform `build_validation` module and pass the assembled configuration. The sumaform `main.tf` itself remains clean and environment-agnostic.

### tfvars files

Each environment has a dedicated `.tfvars` file under `tfvars/build-validation-tfvars/`. The file naming convention is:

```
<product_version>_<image_type>_build_validation_<location>.tfvars
```

For example: `suma50_micro_build_validation_nue.tfvars`

Each tfvars file defines two top-level variables:

**`ENVIRONMENT_CONFIGURATION`** — a map describing every node in the environment. Each key matches a resource name known to the sumaform `build_validation` module. The presence of a key is what triggers deployment of that node. Most nodes only require `mac` and `name`; some have additional fields:

```hcl
ENVIRONMENT_CONFIGURATION = {
  # Core infrastructure — always present
  controller = {
    mac  = "xx:xx:xx:xx:xx:xx"
    name = "controller"
  }
  server_containerized = {
    mac             = "xx:xx:xx:xx:xx:xx"
    name            = "server"
    image           = "slemicro55o"
    string_registry = false
  }
  proxy_containerized = {
    mac             = "xx:xx:xx:xx:xx:xx"
    name            = "proxy"
    image           = "slemicro55o"
    string_registry = false
  }

  # Optional minions — only deployed when declared
  sles15sp7_minion = {
    mac  = "xx:xx:xx:xx:xx:x"
    name = "sles15sp7-minion"
  }
  rocky8_minion = {
    mac  = "xx:xx:xx:xx:xx:xx"
    name = "rocky8-minion"
  }
  # ... more minions

  # s390x minions require an additional userid field
  sles15sp5s390_minion = {
    mac    = "xx:xx:xx:xx:xx:xx"
    name   = "sles15sp5s390-minion"
    userid = "SXXMINUE"
  }

  product_version = "x.x-released"
  name_prefix     = "suma-bv-xx-micro-"
  url_prefix      = "https://ci.suse.de/view/Manager/view/Manager-qe/job/manager-x.x-micro-qe-build-validation"
}
```

**`BASE_CONFIGURATIONS`** — a map of hypervisor connection details. For single-provider sites this contains one entry (`base_core` plus any architecture-specific entries like `base_arm`). For multi-provider sites (SLC), it contains one entry per hypervisor.

```hcl
# Single-provider example (Nuremberg)
BASE_CONFIGURATIONS = {
  base_core = {
    pool               = "ssd"
    bridge             = "br0"
    additional_network = "192.168.xx.0/24"
    hypervisor         = "suma-xx.mgr.suse.de"
  }
  base_arm = {
    pool               = "ssd"
    bridge             = "br0"
    additional_network = null
    hypervisor         = "suma-arm.mgr.suse.de"
  }
}

# Multi-provider example (SLC) — one entry per hypervisor
BASE_CONFIGURATIONS = {
  base_core_1 = {
    pool               = "ssd"
    bridge             = "brx"
    additional_network = "192.168.xx.0/24"
    hypervisor         = "suma-slc-xx.mgr.suse.de"
  }
  base_core_2 = {
    pool               = "ssd"
    bridge             = "br1"
    additional_network = "192.168.xx.0/24"
    hypervisor         = "suma-slc-xx.mgr.suse.de"
  }
}
```

The file also defines mail subject templates and the `LOCATION` variable (e.g. `"nue"` or `"slc"`), which `location.tfvars` uses to inject the correct network settings.

### tfvars generation

Before calling terracumber, the Jenkins pipeline runs `prepare_tfvars.py` to assemble the final `terraform.tfvars`:

```
jenkins_pipelines/scripts/tf_vars_generator/prepare_tfvars.py
```

This script merges several sources into one file:

- The environment's static `.tfvars` file (MAC addresses, names, images, …)
- `tfvars/location.tfvars` (network parameters specific to the deployment site)
- Dynamic values injected at pipeline runtime via `--inject` flags (container repositories, Cucumber branch, product version, …)

For **standard BV pipelines**, the script also accepts a `--clean` / `--keep-resources` option to strip minions that are not in the `minions_to_run` parameter, so the same tfvars file can be used for both full and partial runs without editing it manually.

For **personal BV pipelines**, the script accepts `--env-file` and `--user` to build a configuration from a personal environment reference, plus individual `--minion1` … `--minion7` flags to select which minions to include.

The output is written to `terraform.tfvars` in the sumaform working directory and passed directly to terracumber via `--tf_configuration_files`.

## Mail templates

The `mail_templates/` directory contains the email templates used for pipeline notifications. Each BV environment references two templates: one for Cucumber results and one for environment setup failures.

For more information refer to the [terracumber documentation](https://github.com/uyuni-project/terracumber).
