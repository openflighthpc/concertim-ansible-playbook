#!/bin/bash

set -e
set -o pipefail

if [ -z "${AWS_ACCESS_KEY_ID}" ] ; then
  echo "AWS_ACCESS_KEY_ID environment variable not set" >&2
  exit 1
fi

if [ -z "${AWS_SECRET_ACCESS_KEY}" ] ; then
  echo "AWS_SECRET_ACCESS_KEY environment variable not set" >&2
  exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"/..

echo "=== Building concertim image ==="

docker-compose \
  --file docker/docker-compose.yml \
  --project-directory . \
  build  \
  --build-arg=AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
  --build-arg=AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
  concertim

echo "=== Building proxy image ==="

docker-compose \
  --file docker/docker-compose.yml \
  --project-directory . \
  build  \
  proxy

echo "=== Starting containers ==="

docker-compose \
  --file docker/docker-compose.yml \
  --project-directory . \
  up --detach

echo "=== Migrating database ==="

docker-compose \
  --file docker/docker-compose.yml \
  --project-directory . \
  run --rm --user www-data -e RAILS_ENV=production concertim \
    bash -c 'cd /opt/concertim/opt/ct-visualisation-app/core && bin/rails db:create --trace'

docker-compose \
  --file docker/docker-compose.yml \
  --project-directory . \
  run --rm --user www-data -e RAILS_ENV=production concertim \
    bash -c 'cd /opt/concertim/opt/ct-visualisation-app/core && bin/rails db:migrate --trace'


echo "=== Stopping containers ==="

docker-compose \
  --file docker/docker-compose.yml \
  --project-directory . \
  stop
