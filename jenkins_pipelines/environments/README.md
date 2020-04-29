# Contents

This directory contains the Jenkinsfiles used by each one of our cucumber or reference Jenkins jobs.

We use [Scripted Pipelines](https://www.jenkins.io/doc/book/pipeline/syntax/#scripted-pipeline) in this folder and **note** [Declarative Pipelines](https://www.jenkins.io/doc/book/pipeline/syntax/#declarative-pipeline).

The reason is that while Declarative Pipelines are easier, they are not enough flexible for what we need, and they don't really allow to easy reuse code.

# Files

Each file defines the parameters (and default values), cron configuration and old build removal for each job. Then the correct code from `commons` folder is called.

If you want to run a build for a Job changing a parameter value only once, you can do it from Jenkins.

If you want to make that change permanent for several builds (or forever), then you need to edit the Job's file here. Just change the default value.

For `manager-Test*-cucumber` jobs, squads can also decide to add more parameters, but it's strongly recommended that we keep the same parameters for all jobs, so maintenance is easier.

**NOTE:** The old pipelines at [../manager_testsuite](../manager_testsuite) and [../uyuni_testsuite](../uyuni_testsuite) are now deprecated and should not be maintained. They are only there until migration of the QA jobs is possible.

# "common" folder

Contains the real deal. The code to run the steps such as a git cloning, terracumber provisioning, cucumber testsuite steps, etc.

Currently there are two groovy files:

- [common/pipeline.groovy](common/pipeline.groovy) is used on jobs that run a cucumber testsuite.
- [pipeline-reference.groovy](pipeline-reference.groovy) is used on jobs that provisiong reference environments (they don't use cucumber at all)

At some point we should consider a refactor of the two files, to unify code that is used at both "pipelines".

Needless to say, new groovy files can be defined if your needs are different.
