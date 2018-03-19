#! /bin/bash

PR_BRANCH=$(cat "/.gitarro_vars" | grep "GITARRO_PR_BRANCH:" | cut -d ":" -f2 | xargs)
MAINTF=$1

sed -i "s/Manager/$PR_BRANCH/g" $MAINTF
