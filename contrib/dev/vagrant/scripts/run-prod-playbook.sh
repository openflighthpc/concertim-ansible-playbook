#!/bin/bash

set -e
set -o pipefail

ansible-playbook \
  --inventory /ansible-prod/inventory.ini \
  --extra-vars "gh_token=$GH_TOKEN" \
  --extra-vars @/ansible-prod/etc/globals.yaml \
  /ansible-prod/playbook.yml "$@"
