#! /bin/bash

set -e

export OSCRC="$HOME/jenkins/.oscrc"
export OBS_PROJ=$1
export TEST=1

# go and build the packages
rel-eng/build-packages-for-obs.sh

# .. now submitt what's collected in "$WORKSPACE/SRPMS"
rel-eng/push-packages-to-obs.sh
