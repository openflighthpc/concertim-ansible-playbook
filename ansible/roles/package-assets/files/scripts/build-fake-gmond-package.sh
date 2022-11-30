#!/bin/bash

# set -x
set -e
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GH_ORG=alces-flight
PACKAGE_DIR="${PACKAGE_DIR:-${SCRIPT_DIR}/../tmp/packages}"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/../tmp/repos}"

checkout_source() {
    local repo_name
    repo_name="concertim-${project_name}"
    if [ -d "${project_name}" ] ; then
        pushd "${project_name}" > /dev/null
        echo "Updating repo"
        git fetch --quiet origin
    else
        echo "Cloning ${repo_name} repo into ${project_name}"
        git clone --quiet https://${GH_TOKEN}@github.com/${GH_ORG}/${repo_name}.git ${project_name}
        pushd "${project_name}" > /dev/null
    fi
    local ref_type
    ref_type=$(git_ref_type "${project_tag}")
    if [ "${ref_type}" == "branch" ] ; then
        echo "Using ${ref_type} ${project_tag} ($(git rev-parse HEAD))"
    else
        echo "Using ${ref_type} ${project_tag}"
    fi
    git checkout --quiet "${project_tag}"
    git merge --quiet @{upstream}
    popd > /dev/null
}

create_tar_file() {
    local project_dir prefix
    project_dir="${PACKAGE_DIR}/${release}/demo"
    prefix="${TAR_PREFIX:-${project_name}}/"
    tar_file_name="${project_dir}/${TAR_FILE_BASE_NAME:-${project_name}}"

    mkdir -p "${project_dir}"
    echo "Creating tar file ${tar_file_name}.tgz"
    git archive --format tar --prefix "${prefix}" --output "${tar_file_name}.tar" HEAD
    gzip "${tar_file_name}.tar"
    mv "${tar_file_name}.tar.gz" "${tar_file_name}.tgz"
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
    local release project_name project_tag
    project_name="${1}"
    if [ "${project_name}" == "" ] ; then
        echo "usage: $(basename $0) PROJECT RELEASE [TAG]" >&2
        exit 1
    fi
    release="${2}"
    if [ "${release}" == "" ] ; then
        echo "usage: $(basename $0) PROJECT RELEASE [TAG]" >&2
        exit 1
    fi
    project_tag="${3}"
    if [ "${project_tag}" == "" ] ; then
        project_tag="${release}"
    fi
    if [ "${GH_TOKEN}" == "" ] ; then
        echo "Environment variable GH_TOKEN not found" >&2
        exit 1
    fi

    mkdir -p "${BUILD_DIR}"
    mkdir -p ${PACKAGE_DIR}
    cd "${BUILD_DIR}"
    checkout_source
    cd "${project_name}"
    create_tar_file
}

main "$@"
