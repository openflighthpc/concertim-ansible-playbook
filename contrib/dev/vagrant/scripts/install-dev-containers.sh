#!/bin/bash

set -e
set -o pipefail

ansible-playbook \
  --inventory /ansible/inventory.ini \
  --extra-vars "gh_token=$GH_TOKEN" \
  --extra-vars @/ansible/etc/globals.yaml \
  /ansible-dev/install-dev-containers.yml "$@"
