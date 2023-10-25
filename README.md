# Building and configuring Alces Concertim

This repository contains ansible playbooks for building and deploying Alces
Concertim as a set of Docker containers.  There is also a second ansible
playbook that builds Alces Concertim on a Vagrant VM which is suitable for
development of Concertim.

## Deploying Alces Concertim

To deploy Alces Concertim, visit the [releases
page](https://github.com/alces-flight/concertim-ansible-playbook/releases) and
select the release you want to deploy. The release notes for that release will
contain instructions for deploying Concertim as Docker containers.

Alternatively, if you are looking to build from the `main` branch,
follow [these instructions](production/README.md).

## Developing

For details on how to develop and test the ansible deployment playbook see
[production DEVELOPMENT](production/DEVELOPMENT.md).

If you are looking for details on how to develop the Concertim services
themselves see the [vagrant README](vagrant/README.md).
