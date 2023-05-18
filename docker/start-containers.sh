#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"/..

echo "=== Starting containers ==="

docker compose \
  --file docker/docker-compose.yml \
  --project-directory . \
  up "$@"
