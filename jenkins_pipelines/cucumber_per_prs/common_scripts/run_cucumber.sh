#! /bin/bash

set -ex
ssh_flags="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
cucumber_test="ssh $ssh_flags root@$7 run-testsuite"
PR_NUMBER=$(cat "$8/.gitarro_vars" | grep "GITARRO_PR_NUMBER:" | cut -d ":" -f2 | xargs)
gitarro.ruby2.1  -r "$1" -c "$2" -d "$3" -g $4 -u "$5" -b "$6" -t "$cucumber_test" -P "$PR_NUMBER"
