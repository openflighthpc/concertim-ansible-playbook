#!/bin/bash

set -e
set -o pipefail

add-apt-repository --yes ppa:ansible/ansible
apt install --yes ansible
