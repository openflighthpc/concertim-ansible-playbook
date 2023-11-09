#!/bin/bash

set -e
set -o pipefail

export DEBIAN_FRONTEND=noninteractive
apt update --yes
apt install --yes ansible python3-docker
