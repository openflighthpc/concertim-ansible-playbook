#!/bin/bash

# set -x
set -e
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PACKAGE_DIR="${PACKAGE_DIR:-${SCRIPT_DIR}/../tmp/packages}"
BUCKET="s3://alces-flight/concertim/packages/"

main() {

    local dryrun
    dryrun=""
    yes=""

    while [[ $# -gt 0 ]] ; do
        case "$1" in
            --dryrun|--dry-run)
                dryrun="--dryrun"
                shift
                ;;
            --yes|-y)
                yes="yes"
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done

    echo "Looking for packages in $( realpath --relative-to="." ${PACKAGE_DIR} )"
    echo -e "The following packages will be synced to ${BUCKET}\n"
    find "${PACKAGE_DIR}" -type f -exec realpath --relative-to="${PACKAGE_DIR}" '{}' \;

    if [ "${yes}" != "yes" ] ; then
        echo -e "\nMake certain that they are correctly namespaced with the version."
        echo "Press enter to continue or ctrl-c to abort."
        read
        echo "Continuing with upload"
    fi

    aws s3 sync ${dryrun} "${PACKAGE_DIR}" "${BUCKET}"
}

main "$@"
