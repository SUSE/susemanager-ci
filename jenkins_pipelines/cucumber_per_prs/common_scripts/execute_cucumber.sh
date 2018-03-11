#! /bin/bash

ssh_flag=$1
ctl_node=$2
exec_test=$3

echo
echo "executing cucumber for pull-request"
echo

ssh $ssh_flags -tt root@$ctl_node "$exec_tests"
