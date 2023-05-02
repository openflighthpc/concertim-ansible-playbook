# Building and configuring Alces Concertim

This repository contains ansible playbooks for building an Alces Concertim
appliance.  Alces Concertim can either be built as a standard VM or as Docker
images.

## Building Alces Concertim

To build Alces Concertim, visit the [releases
page](https://github.com/alces-flight/concertim-ansible-playbook/releases) and
select the release you want to build.

The release notes for that release will contain a link to the relevant build
instructions for building Concertim as a VM, and another link to the
instructions for building Concertim as Docker images.

## Building Alces Concertim assets

The ansible `build-playbook.yml` playbook requires certain assets to be
available in S3.  To create those assets follow the [asset building
instructions](ansible/asset-building.md).

## Developing

See the [vagrant README](vagrant/README.md) for details on how to use Vagrant
to develop and test the ansible playbooks above.
