#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"/..

if [ ! -f "docker/secrets/aws-credentials.yml.enc" ] ; then
  echo "secrets file docker/secrets/aws-credentials.yml.enc does not exist" >&2
  exit 1
fi

if [ ! -f "docker/secrets/vault-password.txt" ] ; then
  echo "secrets file docker/secrets/vault-password.txt does not exist" >&2
  exit 1
fi

echo "=== Building metrics, visualisation and proxy images ==="

docker-compose \
  --file docker/docker-compose.yml \
  --project-directory . \
  build  \
  metrics visualisation

cat <<EOF >&2

Build completed.  You should now remove the AWS credentials.

  rm docker/secrets/aws-credentials.yml* docker/secrets/vault-password.txt

You may also wish to remove the builder images as they contain the AWS
credentials.  These can be safely removed.

  docker image ls --filter "label=concertim.role=builder"
  docker image rm \$(docker image ls --filter "label=concertim.role=builder" -q)

EOF
