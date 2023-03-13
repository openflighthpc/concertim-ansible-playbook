# Building and configuring Alces Concertim

This repository contains ansible playbooks for building and configuring
Alces Concertim.

## Building Alces Concertim

To build Alces Concertim, visit the [releases
page](https://github.com/alces-flight/concertim-bootstrap/releases) and select
the release you want to build.  At the time of writing you probably want to
use the most recent `revival-X` release, e.g., `revival-11`.

The release notes for that release will contain a link to the relevant build
instructions.

## Developing

See the [vagrant README](vagrant/README.md) for details on how to use Vagrant
to develop and test the ansible playbooks above.

## Previous attempts

See the tag `bootstrap-via-safe-persistent-reimplementation` for the now
aborted attempt to bootstrap by reimplementing parts of `safe-persistent
deploy`.
