#! /bin/bash

PR_BRANCH=$(cat "/.gitarro_vars" | grep "GITARRO_PR_BRANCH:" | cut -d ":" -f2 | xargs)
MAINTF=$1
BRANCH=$2
sed -i "s/$BRANCH/$PR_BRANCH/g" $MAINTF
