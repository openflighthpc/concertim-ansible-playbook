# Building and configuring Alces Concertim

This repository contains ansible playbooks for building and deploying Alces
Concertim as a set of Docker containers.  There is also a second ansible
playbook that builds Alces Concertim on a Vagrant VM which is suitable for
development of Concertim.

## Deploying Alces Concertim

You are viewing release `v0.2.2` of Alces Concertim Ansible Playbook.
To deploy this version of Alces Concertim follow [these
instructions](production/README.md).

To deploy an alternate release of Alces Concertim select the tag for that
release and follow the deployment instructions there.

To deploy the development version of Alces Concertim select the `main` branch
and follow the deployment instructions there.

## Developing

For details on how to develop and test the ansible deployment playbook see
[production DEVELOPMENT](production/DEVELOPMENT.md).

If you are looking for details on how to develop the Concertim services
themselves see the [vagrant README](vagrant/README.md).
