# Pipelines for SUSE-Manager

- 1) Manager GitHub pull-request unit/tests 

- 2) Manager performance testsuite

- 3) Uyuni pipelines which are the same as 1)


This is not running anywhere, is only experimental code not in prod.

- Manager Github pull-request cucumber functional tests

### Manager GitHub pull-request unit/tests

This directory contains all pipelines that are executed for testing prs for spacewalk.

This pipelines use the same patterns, which is to use the gitarro tools for github PRS.
1) Use gitarro https://github.com/openSUSE/gitarro


### Manager performance testsuite

This dir contains pipelines related to scalabilty tests for suse-manager.

#### How to make a pipeline from scratch 

If you are new to pipeline, start reading this:

https://jenkins.io/doc/book/pipeline/getting-started/#defining-a-pipeline-in-scm

##### Steps to create a pipeline:

0) Create a Jenkins Pipeline Job
1) Configure Jenkins to clone from your custom PR Branch. ( in this way you can tests the pipeline before it get merged in master)  
2) When the PR is merged, update your Job Pipeline to use the **master** branch
3) Create a directory if you are creating pipelines for a special topic. Otherwise add it in the proper namespaces.
