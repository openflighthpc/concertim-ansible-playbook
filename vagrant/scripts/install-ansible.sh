#!/bin/bash

set -e
set -o pipefail

export DEBIAN_FRONTEND=noninteractive
add-apt-repository --yes ppa:ansible/ansible
apt install --yes ansible
