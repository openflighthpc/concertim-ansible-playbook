#!/bin/bash

set -e
set -o pipefail

ansible-playbook \
  --inventory /ansible-dev/inventory.ini \
  /ansible-dev/dev-playbook.yml "$@"
