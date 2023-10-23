#!/bin/bash

set -e
set -o pipefail

usage() {
    cat <<EOF
Usage: $(basename $0) BOX_NAME
Rebuild BOX_NAME as a Flight Concertim.
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

# FSR, this is much more reliable if separated into multiple separate runs.
vagrant up --no-provision "${BOX_NAME}"
vagrant provision --provision-with swap "${BOX_NAME}"
vagrant provision --provision-with install_ansible "${BOX_NAME}"
vagrant provision --provision-with install_docker "${BOX_NAME}"
# vagrant provision --provision-with run_build_playbook "${BOX_NAME}"
# vagrant provision --provision-with run_alt_playbook "${BOX_NAME}"
