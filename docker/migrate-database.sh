#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"/..

echo "=== Migrating database ==="

"${SCRIPT_DIR}"/start-containers.sh --detach db

if docker compose version > /dev/null 2>&1 ; then
  DOCKER_COMPOSE="docker compose"
else
  DOCKER_COMPOSE="docker-compose"
fi

${DOCKER_COMPOSE} \
  --file docker/docker-compose.yml \
  --project-directory . \
  run --rm --user www-data -e RAILS_ENV=production visualisation \
    bash -c 'cd /opt/concertim/opt/ct-visualisation-app/core && bin/rails db:create --trace'

${DOCKER_COMPOSE} \
  --file docker/docker-compose.yml \
  --project-directory . \
  run --rm --user www-data -e RAILS_ENV=production visualisation \
    bash -c 'cd /opt/concertim/opt/ct-visualisation-app/core && bin/rails db:migrate --trace'

"${SCRIPT_DIR}"/stop-containers.sh
