#! /bin/bash

set -e

## We need after all tests, to push the head Manager pkg to our obs repo
# otherwise it can be that we are not updated with latest pkgs.

export OSCRC="$HOME/jenkins/.oscrc"
export TEST=1
export OBS_PROJ=$1
GIT_BRANCH=$2

git clone --depth 1 -b $GIT_BRANCH git@github.com:SUSE/spacewalk.git spacewalk_restore_$GIT_BRANCH
cd spacewalk_restore_$GIT_BRANCH

# go and build the packages
rel-eng/build-packages-for-obs.sh

# .. now submitt what's collected in "$WORKSPACE/SRPMS"
rel-eng/push-packages-to-obs.sh

cd ..
rm -rf spacewalk_restore_$GIT_BRANCH
