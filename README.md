# Building and configuring Alces Concertim

This repository contains ansible playbooks for building and deploying Alces
Concertim.  Alces Concertim can either be built as a standard VM or deployed as
Docker containers from pre-built images.

## Deploying Alces Concertim

To deploy Alces Concertim, visit the [releases
page](https://github.com/alces-flight/concertim-ansible-playbook/releases) and
select the release you want to deploy.

The release notes for that release will contain a link to the relevant build
instructions for building Concertim as a VM, and another link to the
instructions for deploying Concertim as Docker containers.

## Building Docker images

Deploying Concertim as a set of Docker containers, requires docker images to
have been built and uploded to a docker registry.  See [these
instructions](docker/README.md) for details on how to do this.

## Building Alces Concertim assets

Building Concertim as a VM and building the docker images both require certain
assets to be available in S3.  To create those assets follow the [asset
building instructions](ansible/asset-building.md).

## Developing

See the [vagrant README](vagrant/README.md) for details on how to use Vagrant
to develop and test the ansible playbooks above.
