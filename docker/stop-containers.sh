#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"/..

if docker compose version > /dev/null 2>&1 ; then
  DOCKER_COMPOSE="docker compose"
else
  DOCKER_COMPOSE="docker-compose"
fi

echo "=== Stopping containers ==="

${DOCKER_COMPOSE} \
  --file docker/docker-compose.yml \
  --project-directory . \
  stop
