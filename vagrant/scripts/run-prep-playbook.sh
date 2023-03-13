#!/bin/bash

set -e
set -o pipefail

ansible-playbook --inventory /ansible/inventory.ini /ansible/prep-playbook.yml "$@"
