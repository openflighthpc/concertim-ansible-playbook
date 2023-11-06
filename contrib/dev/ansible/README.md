# Creating a development environment for developing the Concertim Services

This directory contains an ansible playbook to build an Alces Concertim machine
suitable for developing the Metric Reporting Daemon and Visualisation App
components.  It is not intended for a production deployment.

The easiest way to use this playbook is to follow the instructions at [contrib/dev/README.md](/contrib/dev/README.md).
If those instructions don't work for you, continue reading.

Following the instructions here will result in a single VM machine running
development deployments of the Metric Reporting Daemon and Visualisation App
along with any services they require.

If you are looking for a production deployment of Concertim, see the
[production README](/production/README.md), for details on how to build
Concertim as a set of Docker containers.

The instructions here will work for the current `main` branch, your milage may
vary with other versions.

## Prerequisites

* An Ubuntu 22.04 (jammy) machine with at least 3GiB of memory and at least 2
  CPUs.  This machine will become the Alces Concertim machine.  It is expected
  that this would be a fresh virtual machine.
* Root access on that Ubuntu machine.

## Overview

The process is as follows.  Steps 2 through 5 are to be ran in the root shell
obtained in step 1.  They are described in more detail below.

1. Log into the virtual machine that is going to become your Concertim
   development appliance and gain root access.
2. Install ansible and dependencies.
3. Clone this git repository and checkout the correct tag.
4. Run the build playbook.

## Gather GitHub

You will need GitHub credentials to clone this repository, the metric reporting
daemon and the visualisation app repositories.

Obtaining these credentials is left as an exercise for the reader.

The following code snippets assumes that the credentials are available in the
`GH_TOKEN` environment variables.  If they are you can copy and paste the code
snippets.

## Install ansible

The ansible playbook has been tested against `ansible` version `5.10.0` other
versions of ansible may work but have not been tested.  Ansible `5.10.0` can
be installed with the following.

```bash
add-apt-repository --yes ppa:ansible/ansible
apt install --yes ansible
```

## Clone the needed git repositories

Clone this git repository onto the virutal machine that is going to become your
development environment. This git repository is a private repository, so you
will need to provide credentials to clone it.

```bash
cd /root
git clone git@github.com:alces-flight/concertim-ansible-playbook.git
ln -s /root/concertim-ansible-playbook/contrib/dev/ansible /ansible-dev
```

Clone the metric reporting daemon and visualisation app repositories

```sh
mkdir -p /opt/concertim/dev
cd /opt/concertim/dev
git clone git@github.com:alces-flight/concertim-metric-reporting-daemon.git ct-metric-reporting-daemon
git clone git@github.com:alces-flight/concertim-ct-visualisation-app.git ct-visualisation-app
```

## Run the build playbook

```bash
ansible-playbook \
  --inventory /ansible-dev/inventory.ini \
  /ansible-dev/dev-playbook.yml
```
