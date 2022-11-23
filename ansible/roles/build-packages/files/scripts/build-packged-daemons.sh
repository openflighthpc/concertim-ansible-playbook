#!/bin/bash

# set -x
set -e
set -o pipefail

# DAEMONS is an array of the daemons that are going to be packaged.  TAGS is
# an associative array mapping daemons to the tag to build.
declare -a DAEMONS=(
  ailsa
  ct-capacity-daemon
  enid
  maggie
  martha
  meryl
  theresa
)
declare -A TAGS=(
  [ailsa]=main
  [ct-capacity-daemon]=main
  [enid]=main
  [maggie]=main
  [martha]=main
  [meryl]=main
  [theresa]=main
)

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GH_ORG=alces-flight
PACKAGE_DIR="${SCRIPT_DIR}/../tmp/packages"
BUILD_DIR="${SCRIPT_DIR}/../tmp/repos"

remove_previous_builds() {
    if [ ! -d ${PACKAGE_DIR} ]; then
        mkdir -p ${PACKAGE_DIR}
    else
        rm -rf ${PACKAGE_DIR}/*
    fi
}

create_build_yml() {
    echo -e "Creating config/build.yml"
    local version sha date

    version=$(
      git tag --list --points-at HEAD --sort=-v:refname | \
          grep '^v[[:digit:]]' | \
          head -n 1
    ) || true
    if [ "$version" == "" ] ; then
        version=$(git rev-parse --abbrev-ref HEAD)
    fi
    sha=$(git rev-parse HEAD)
    date=$(git log -1 --format=%cd --date iso)

    cat <<EOF > config/build.yml
---
build_version: "${version}"
build_rev: "${sha}"
build_date: "${date}"
EOF
}

checkout_source() {
    local repo_name
    repo_name="concertim-${daemon}"
    if [ -d "${daemon}" ] ; then
        pushd "${daemon}" > /dev/null
        echo "Updating repo"
        git fetch --quiet origin
    else
        echo "Cloning ${repo_name} repo into ${daemon}"
        gh repo clone "${GH_ORG}/${repo_name}" "${daemon}" -- --quiet
        pushd "${daemon}" > /dev/null
    fi
    tag="${TAGS[${daemon}]}"
    echo "Using $(git_ref_type "${tag}") ${tag}"
    git checkout --quiet "${tag}"
    popd > /dev/null
}

create_tar_file() {
    echo "Creating tar file ${daemon_dir}/${daemon}.tgz"
    git archive --format tar --prefix "${daemon}/" --output "${daemon_dir}/${daemon}.tar" HEAD
}

append_build_yml() {
    tar --append -f "${daemon_dir}/${daemon}.tar" "${daemon}/config/build.yml"
    gzip "${daemon_dir}/${daemon}.tar"
    mv "${daemon_dir}/${daemon}.tar.gz" "${daemon_dir}/${daemon}.tgz"
}


git_ref_type() {
    if git show-ref -q --verify "refs/heads/$1" 2>/dev/null; then
        echo "branch"
    elif git show-ref -q --verify "refs/tags/$1" 2>/dev/null; then
        echo "tag"
    elif git show-ref -q --verify "refs/remotes/$1" 2>/dev/null; then
        echo "branch"
    elif git show-ref -q --verify "refs/remotes/origin/$1" 2>/dev/null; then
        echo "branch"
    elif git rev-parse --verify "$1^{commit}" >/dev/null 2>&1; then
        echo "commit"
    else
        echo "unknown"
    fi
    return 0
}

main() {
    local namespace
    namespace="${1}"
    if [ "${namespace}" == "" ] ; then
        echo "usage: $(basename $0) NAMESPACE" >&2
        exit 1
    fi

    echo "cd ${SCRIPT_DIR}"
    cd "${SCRIPT_DIR}"
    remove_previous_builds
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"

    echo -e "=== Building daemons"
    daemon_dir="${PACKAGE_DIR}/daemons/${namespace}"
    mkdir -p "${daemon_dir}"
    local daemon
    for daemon in ${DAEMONS[@]} ; do
        echo -e "\n== Building daemon ${daemon}"
        checkout_source
        pushd "${daemon}" > /dev/null
        create_build_yml
        create_tar_file
        popd > /dev/null
        append_build_yml
    done
}

main "$@"
