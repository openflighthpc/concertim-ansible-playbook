#!/bin/bash

set -e
set -o pipefail

ansible-playbook \
  --inventory /ansible/inventory.ini \
  --extra-vars "gh_token=$GH_TOKEN" \
  /production/playbook.yml "$@"
