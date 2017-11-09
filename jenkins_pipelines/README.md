# Welcome to our jenkins pipeline Susemanagers!

## How to contribute:

If you are new to pipeline, start reading this:

https://jenkins.io/doc/book/pipeline/getting-started/#defining-a-pipeline-in-scm

# Steps to create a pipeline:

0) Create a Jenkins Pipeline Job
1) Configure Jenkins to clone from your custom PR Branch. ( in this way you can tests the pipeline before it get merged in master)  
2) When the PR is merged, update your Job Pipeline to use the **master** branch

## Manager Prs dir 

This directory contain all pipelines that execute tests on prs.

## For GitHub Pull-Requests tests: 

1) Use gitarro https://github.com/openSUSE/gitarro
