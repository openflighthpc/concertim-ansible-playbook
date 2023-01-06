#!/bin/bash

set -e
set -o pipefail

usage() {
    cat <<EOF
Usage: $(basename $0) BOX_NAME RELEASE
Rebuild BOX_NAME as a MIA using release RELEASE.
EOF
}

if [ $# -lt 2 ] ; then
    usage
    exit 1
fi

BOX_NAME="$1"
MIA_RELEASE_TAG="$2"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "${SCRIPT_DIR}"/..
source "${SCRIPT_DIR}"/prepare-env.sh
vagrant destroy --force "${BOX_NAME}"

# FSR, this is much more reliable if separated into multiple separate runs.
vagrant up --no-provision "${BOX_NAME}"
vagrant provision --provision-with swap "${BOX_NAME}"
vagrant provision --provision-with apt-upgrade "${BOX_NAME}"
vagrant provision --provision-with prep_playbook "${BOX_NAME}"

# Reboot the machine so that changes configured in `prep_playbook` can take
# place.
vagrant reload --force "${BOX_NAME}"
export MIA_RELEASE_TAG
vagrant provision --provision-with build_playbook "${BOX_NAME}"
vagrant provision --provision-with configure_playbook "${BOX_NAME}"
