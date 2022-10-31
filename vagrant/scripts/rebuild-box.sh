#!/bin/bash

set -e
set -o pipefail

usage() {
    cat <<EOF
Usage: $(basename $0) BOX_NAME
Destroy, create and provision box BOX_NAME.
EOF
}

if [ $# -lt 1 ] ; then
    usage
    exit 1
fi

BOX_NAME="$1"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "${SCRIPT_DIR}"/..
source "${SCRIPT_DIR}"/prepare-env.sh
vagrant destroy --force "${BOX_NAME}"

# FSR, this is much more reliable if separated into two separate runs.
vagrant up --provision-with swap,apt-upgrade "${BOX_NAME}"
vagrant provision --provision-with prep_playbook "${BOX_NAME}"

# Reboot the machine so that changes configured in `prep_playbook` can take
# place.
vagrant reload --force "${BOX_NAME}"
vagrant provision --provision-with build_playbook "${BOX_NAME}"
vagrant provision --provision-with configure_playbook "${BOX_NAME}"
