# Contents

- [environments](environments/): Testsuite (cucumber) and reference environments
- [manager_testsuite](manager_testsuite/): Manager testsuite pipelines for QA/QAM (deprecated)
- [uyuni_testsuite](uyuni_testsuite/): Uyuni testsuite pipelines for QA/QAM (deprecated)
- [manager_prs](manager_prs/): Manager PR Checks
- [uyuni_prs](uyuni_prs/): Uyuni PR Checks

## Testsuite (cucumber) and reference environments

The directory contains jobs definitions for all of our testsuite and reference environment jobs.

Check [environments/README.md](environments/README.md) for more details.

## Manager and Uyuni testsuite pipelines for QA/QAM (deprecated)

**WARNING:** This is deprecrated and only exists until QAM jobs can be migrated to the new pipelines with terracumber at [environments](environments/) folder.

This directory contains pipelines related to QA and QAM testsuites for suse-manager.

### How to make a pipeline from scratch 

If you are new to pipeline, start reading this:

https://jenkins.io/doc/book/pipeline/getting-started/#defining-a-pipeline-in-scm

#### Steps to create a pipeline:

0) Create a Jenkins Pipeline Job
1) Configure Jenkins to clone from your custom PR Branch. ( in this way you can tests the pipeline before it get merged in master)  
2) When the PR is merged, update your Job Pipeline to use the **master** branch
3) Create a directory if you are creating pipelines for a special topic. Otherwise add it in the proper namespaces.

## Manager PR Checks/Uyuni PR Checks

This directory contains all pipelines that are executed for testing prs for spacewalk.

This pipelines use the same patterns, which is to use the gitarro tools for github PRS.
1) Use gitarro https://github.com/openSUSE/gitarro
