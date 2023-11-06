#!/bin/bash

# set -x
set -e
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GH_ORG=alces-flight
PACKAGE_DIR="${PACKAGE_DIR:-${SCRIPT_DIR}/../tmp/packages}"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/../tmp/repos}"
REPO_SUBDIR="${REPO_SUBDIR:-""}"

# Expected environment variables that have no sensible default.
if [ "${RELEASE}" == "" ] ; then
    echo "Environment variable RELEASE not found" >&2
    exit 1
fi
if [ "${GH_TOKEN}" == "" ] ; then
    echo "Environment variable GH_TOKEN not found" >&2
    exit 1
fi
if [ "${GH_REPO}" == "" ] ; then
    echo "Environment variable GH_REPO not found" >&2
    exit 1
fi
if [ "${PKG_NAME}" == "" ] ; then
    echo "Environment variable PKG_NAME not found" >&2
    exit 1
fi
if [ "${BUILD_TAG}" == "" ] ; then
    echo "Environment variable BUILD_TAG not found" >&2
    exit 1
fi
if [ "${PKG_TYPE}" == "" ] ; then
    echo "Environment variable PKG_TYPE not found" >&2
    exit 1
fi

# Return path to build.yml from project root.
get_build_yaml() {
  echo config/build.yml
}

create_build_yml() {
    local build_yml
    build_yml="$(get_build_yaml)"
    echo -e "Creating ${build_yml}"
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
    cat <<EOF > "${build_yml}"
---
build_version: "${version}"
build_rev: "${sha}"
build_date: "${date}"
EOF
}

checkout_source() {
    if [ -d "${PKG_NAME}" ] ; then
        pushd "${PKG_NAME}" > /dev/null
        echo "Updating repo"
        git fetch --quiet origin
    else
        echo "Cloning ${GH_REPO} repo into ${PKG_NAME}"
        git clone --quiet https://${GH_TOKEN}@github.com/${GH_ORG}/${GH_REPO}.git ${PKG_NAME}
        pushd "${PKG_NAME}" > /dev/null
    fi
    local ref_type
    ref_type=$(git_ref_type "${BUILD_TAG}")
    if [ "${ref_type}" == "branch" ] ; then
        echo "Using ${ref_type} ${BUILD_TAG} ($(git rev-parse HEAD))"
    else
        echo "Using ${ref_type} ${BUILD_TAG}"
    fi
    git checkout --quiet "${BUILD_TAG}"
    if [ "${ref_type}" == "branch" ] ; then
	    git merge --quiet @{upstream}
    fi
    popd > /dev/null
}

create_tar_file() {
    echo "Creating tar file $( realpath --relative-to="." ${project_dir} )/${PKG_NAME}.tgz"
    git archive --format tar --prefix "${PKG_NAME}/" --output "${project_dir}/${PKG_NAME}.tar" HEAD
}

append_build_yml() {
    tar --append -f "${project_dir}/${PKG_NAME}.tar" "${PKG_NAME}/$(get_build_yaml)"
    gzip "${project_dir}/${PKG_NAME}.tar"
    mv "${project_dir}/${PKG_NAME}.tar.gz" "${project_dir}/${PKG_NAME}.tgz"
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
    mkdir -p ${PACKAGE_DIR}
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"
    project_dir="${PACKAGE_DIR}/${RELEASE}/${PKG_TYPE}s"
    mkdir -p "${project_dir}"

    echo -e "=== Packaging project: ${PKG_NAME} from ${GH_REPO}/${REPO_SUBDIR} @ ${BUILD_TAG}"
    checkout_source
    pushd "${PKG_NAME}/${REPO_SUBDIR}" > /dev/null

    create_build_yml
    create_tar_file
    popd > /dev/null
    append_build_yml
}

main "$@"
