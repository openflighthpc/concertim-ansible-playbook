#!/bin/bash

# set -x
set -e
set -o pipefail

# PROJECTS and the branch to build are read from the Environment variable
# PROJECTS.  It is a space separated list of TYPE:NAME:TAG tripples.  E.g.,
#
#   PROJECTS="daemon:metric-reporting-daemon:main daemon:another-daemon:dev"
#
# The tag could be a tag, branch or commit.
if declare -p PROJECTS >/dev/null 2>&1 ; then
    copy="${PROJECTS}"
    unset PROJECTS
    declare -a PROJECTS
    for tagged_project in ${copy}; do
        PROJECTS+=("${tagged_project}")
    done
    unset copy
else
    declare -a PROJECTS=()
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GH_ORG=alces-flight
PACKAGE_DIR="${PACKAGE_DIR:-${SCRIPT_DIR}/../tmp/packages}"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/../tmp/repos}"

get_project_type() {
    echo "$1" | cut -d: -f1
}

get_project_name() {
    echo "$1" | cut -d: -f2
}

get_project_tag() {
    echo "$1" | cut -d: -f3
}

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
    if [ "${ref_type}" == "branch" ] ; then
	    git merge --quiet @{upstream}
    fi
    popd > /dev/null
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

package_projects() {
    echo -e "=== Packaging ${#PROJECTS[@]} projects: ${PROJECTS[@]}"
    local loud_project_type project_dir project_type tagged_project project_name project_tag
    for tagged_project in ${PROJECTS[@]} ; do
        project_type=$( get_project_type "${tagged_project}")
        project_name=$( get_project_name "${tagged_project}" )
        project_tag=$( get_project_tag "${tagged_project}" )
        loud_project_type=$(echo "${project_type}" | tr '[:lower:]' '[:upper:]')

        project_dir="${PACKAGE_DIR}/${release}/${project_type}s"
        mkdir -p "${project_dir}"

        echo -e "\n== Packaging ${project_type} ${project_name}"
        checkout_source
        pushd "${project_name}" > /dev/null
        make clean
        make package
        mv "${project_name}.tgz" "${project_dir}"
        popd > /dev/null
    done
}

main() {
    local release
    release="${1}"
    if [ "${release}" == "" ] ; then
        echo "usage: $(basename $0) RELEASE" >&2
        exit 1
    fi
    if [ "${GH_TOKEN}" == "" ] ; then
        echo "Environment variable GH_TOKEN not found" >&2
        exit 1
    fi

    mkdir -p ${PACKAGE_DIR}
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"

    package_projects
}

main "$@"
