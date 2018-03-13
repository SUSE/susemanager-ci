#! /bin/bash 

set -e

export OSCRC="$HOME/jenkins/.oscrc"
export OBS_PROJ=$1
export TEST=1

check_obs_failure() {
  OSC="/usr/bin/osc -A https://api.suse.de"
  # Get failed 
  ${OSC} pr -s 'F' ${OBS_PROJ} | awk '{print}END{exit NR>1}' || {
    echo "Rpm build Failed!"
    echo
    exit 1
  }
}

obs_from_github="$1"
workspace="$2"
scripts="$workspace/jenkins_pipelines/cucumber_per_prs/common_scripts"

###### MAIN #######

$scripts/git2obs.sh '$obs_from_github' '$workspace'
ruby $scripts/check_pkgs_published.rb '$obs_from_github'
check_obs_failure
