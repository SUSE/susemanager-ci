#! /bin/bash

WORKSPACE=$3
PR_BRANCH=$(cat "$WORKSPACE/.gitarro_vars" | grep "GITARRO_PR_BRANCH:" | cut -d ":" -f2 | xargs)
MAINTF=$1
BRANCH=$2
sed -i "s/$BRANCH/$PR_BRANCH/g" $MAINTF
