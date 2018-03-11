#! /bin/bash

set -e

export OSCRC="$HOME/jenkins/.oscrc"
export OBS_PROJ=$1
export TEST=1

#cd "$(dirname "$0")"
check_obs_failure() {
  OSC="/usr/bin/osc -A https://api.suse.de"
  # Get failed 
  ${OSC} pr -s 'F' ${OBS_PROJ} | awk '{print}END{exit NR>1}' || {
    echo "Rpm build Failed!"
    echo
    exit 1
  }
}
### MAIN ####
check_obs_failure
