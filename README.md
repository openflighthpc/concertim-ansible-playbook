# Building and configuring Alces Concertim

This repository contains an ansible playbook for building an Alces Concertim
appliance and an ansible playbook for building assets used by the prior
playbook.

## Building Alces Concertim

To build Alces Concertim, visit the [releases
page](https://github.com/alces-flight/concertim-ansible-playbook/releases) and
select the release you want to build.  At the time of writing you probably want
to use the most recent `revival-X` release, e.g., `revival-20`.

The release notes for that release will contain a link to the relevant build
instructions.

## Building Alces Concertim assets

The ansible `build-playbook.yml` playbook requires certain assets to be
available in S3.  To create those assets follow the [asset building
instructions](ansible/asset-building.md).

## Developing

See the [vagrant README](vagrant/README.md) for details on how to use Vagrant
to develop and test the ansible playbooks above.
