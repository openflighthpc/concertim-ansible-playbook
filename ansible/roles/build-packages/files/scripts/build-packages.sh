#!/bin/bash

# set -x
set -e
set -o pipefail

# APPLIANCES and the branch to build are read from the Environment variable
# APPLIANCES.  It is a space separated list of NAME:TAG pairs.  E.g.,
#
#   APPLIANCES="emma:main mia:dev"
#
# The tag could be a tag, branch or commit.
if declare -p APPLIANCES >/dev/null 2>&1 ; then
    copy="${APPLIANCES}"
    unset APPLIANCES
    declare -a APPLIANCES
    for tagged_project in ${copy}; do
        APPLIANCES+=("${tagged_project}")
    done
    unset copy
else
    declare -a APPLIANCES=()
fi

# DAEMONS and the branch to build are read from the Environment variable
# DAEMONS.  It is a space separated list of NAME:TAG pairs.  E.g.,
#
#   DAEMONS="meryl:main maggie:dev theresa:v1.2.3"
#
# The tag could be a tag, branch or commit.
if declare -p DAEMONS >/dev/null 2>&1 ; then
    copy="${DAEMONS}"
    unset DAEMONS
    declare -a DAEMONS
    for tagged_project in ${copy}; do
        DAEMONS+=("${tagged_project}")
    done
    unset copy
else
    declare -a DAEMONS=()
fi

# MODULES and the branch to build are read from the Environment variable
# MODULES.  It is a space separated list of NAME:TAG pairs.  E.g.,
#
#   MODULES="hacor:main meca:dev scram:v1.2.3"
#
# The tag could be a tag, branch or commit.
if declare -p MODULES >/dev/null 2>&1 ; then
    copy="${MODULES}"
    unset MODULES
    declare -a MODULES
    for td in ${copy}; do
        MODULES+=("${td}")
    done
    unset copy
else
    declare -a MODULES=()
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GH_ORG=alces-flight
PACKAGE_DIR="${PACKAGE_DIR:-${SCRIPT_DIR}/../tmp/packages}"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/../tmp/repos}"
RELEASE_FILE=
VERSION_YML=

get_project_name() {
    echo "$1" | cut -d: -f1
}

get_project_tag() {
    echo "$1" | cut -d: -f2
}

# Return path to build.yml from project root.
get_build_yaml() {
    if [ "${project_name}" == "emma" ]; then
        echo core/config/build.yml
    else
        echo config/build.yml
    fi
}

remove_previous_builds() {
    if [ ! -d ${PACKAGE_DIR} ]; then
        mkdir -p ${PACKAGE_DIR}
    else
        rm -rf ${PACKAGE_DIR}/*
    fi
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

    echo -e "${loud_project_type}: $project_name ($version@$sha $date)" >> $RELEASE_FILE
    cat <<EOF > "${build_yml}"
---
build_version: "${version}"
build_rev: "${sha}"
build_date: "${date}"
EOF
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
    git merge --quiet @{upstream}
    popd > /dev/null
}

create_tar_file() {
    echo "Creating tar file $( realpath --relative-to="." ${project_dir} )/${project_name}.tgz"
    git archive --format tar --prefix "${project_name}/" --output "${project_dir}/${project_name}.tar" HEAD
}

append_build_yml() {
    tar --append -f "${project_dir}/${project_name}.tar" "${project_name}/$(get_build_yaml)"
    gzip "${project_dir}/${project_name}.tar"
    mv "${project_dir}/${project_name}.tar.gz" "${project_dir}/${project_name}.tgz"
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

create_release_and_version_files() {
    # Touch up the RELEASE_FILE and create a sorted version without a header.
    sort "${RELEASE_FILE}" > "${RELEASE_FILE}.sorted"
    echo "Alces Concertim source build, generated `date`" > "${RELEASE_FILE}"
    cat "${RELEASE_FILE}.sorted" >> "${RELEASE_FILE}"

    # Use the sorted RELEASE_FILE to generate the VERSION_YML.
    local most_recent release_revision release_date release_time start_year current_year build_version
    most_recent=$(cat "${RELEASE_FILE}.sorted" | cut -f2 -d"@" | cut -d")" -f1 | sort -n | tail -1 )
    release_revision=$(echo "${most_recent}" | awk '{print $1}')
    release_date=$(echo "${most_recent}" | awk '{print $2}')
    release_time=$(echo "${most_recent}" | awk '{print $3}')
    # start_year=2015
    current_year=$(date '+%Y')
    build_version="XXX" # This is the version number e.g., 8.0.1

    echo "date: ${release_date} ${release_time}" > ${VERSION_YML}
    echo "version: ${build_version}" >> ${VERSION_YML}
    echo "revision: ${release_revision}" >> ${VERSION_YML}
    echo "code_base: ${release}" >> ${VERSION_YML}
    echo "copyright: ${current_year}" >> ${VERSION_YML}
    echo "build_date: ${release_date} ${release_time}" >> ${VERSION_YML}
    echo "build_version: ${build_version}" >> ${VERSION_YML}
    echo "build_revision: ${release_revision}" >> ${VERSION_YML}

    rm "${RELEASE_FILE}.sorted"
}

copy_module_controllers() {
    # Copy across all of the module's controllers for mia.  This will fail if
    # this build run isn't building all of the modules.
    declare -a expected_modules=(sas hacor meca scram oobm)
    declare -A actual_modules
    local module
    for tagged_module in "${MODULES[@]}" ; do
        module=$( get_project_name "${tagged_module}" )
        # actual_modules+=(${module})
        actual_modules["${module}"]=1
    done
    for module in "${expected_modules[@]}" ; do
        # Check if expected module is in actual modules.
        if [ ! "${actual_modules[$module]+_}" ] ; then
            echo "Expected module ${module} to be included in build"
            exit 2
        fi
    done

    local module_dir
    for module in "${expected_modules[@]}" ; do
        echo -e "Including ${module} controllers in tar file"
        module_controlers="${BUILD_DIR}/${module}/app/controllers"
        tar --append -f "${project_dir}/${project_name}.tar" \
            --directory "${module_controlers}" . \
            --transform "s/^/mia\/app\/controllers\/${module}\//"
    done
}

package_projects() {
    local -n projects="$1"
    local loud_project_type project_dir project_type
    project_type="$2"
    echo -e "=== Packaging ${#projects[@]} ${project_type}s: ${projects[@]}"
    loud_project_type=$(echo "${project_type}" | tr '[:lower:]' '[:upper:]')
    project_dir="${PACKAGE_DIR}/${release}/${project_type}s"
    mkdir -p "${project_dir}"
    local tagged_project project_name project_tag
    for tagged_project in ${projects[@]} ; do
        project_name=$( get_project_name "${tagged_project}" )
        project_tag=$( get_project_tag "${tagged_project}" )
        echo -e "\n== Packaging ${project_type} ${project_name}"
        checkout_source
        pushd "${project_name}" > /dev/null
        create_build_yml
        create_tar_file
        popd > /dev/null
        if [ "${project_name}" == "mia" ] ; then
            copy_module_controllers
        fi
        append_build_yml
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
    RELEASE_FILE=${PACKAGE_DIR}/${release}/release.info
    VERSION_YML=${PACKAGE_DIR}/${release}/version.yml

    remove_previous_builds
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"

    package_projects DAEMONS daemon
    package_projects MODULES module
    package_projects APPLIANCES appliance
    create_release_and_version_files
}

main "$@"
