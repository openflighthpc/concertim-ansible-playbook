#!/bin/bash

set -e
set -o pipefail

ansible-playbook \
  --inventory /ansible-dev/inventory.ini \
  --extra-vars "aws_access_key_id=$AWS_ACCESS_KEY_ID aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
  /ansible-dev/build-playbook.yml "$@"
