#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"/..

echo "=== Migrating database ==="

"${SCRIPT_DIR}"/start-containers.sh --detach db

docker compose \
  --file docker/docker-compose.yml \
  --project-directory . \
  run --rm --user www-data -e RAILS_ENV=production visualisation \
    bash -c 'cd /opt/concertim/opt/ct-visualisation-app && bin/rails db:create --trace'

docker compose \
  --file docker/docker-compose.yml \
  --project-directory . \
  run --rm --user www-data -e RAILS_ENV=production visualisation \
    bash -c 'cd /opt/concertim/opt/ct-visualisation-app && bin/rails db:migrate --trace'

"${SCRIPT_DIR}"/stop-containers.sh
