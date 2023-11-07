# Building and configuring Alces Concertim

This directory contains an ansible playbook to build an Alces Concertim machine
suitable for developing the Metric Reporting Daemon and Visualisation App
Concertim components.

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

1. Log into the virtual machine that is going to become the Concertim appliance
   and gain root access.
2. Gather GitHub and S3 credentials.
3. Install ansible and dependencies.
4. Clone this git repository and checkout the correct tag.
5. Run the build playbook.

## Gather GitHub and S3 credentials

You will need GitHub credentials to clone this repository.

You will also need S3 credentials to allow the playbook to download packages
from S3.  The credentials need to allow downloading from
`s3://alces-flight/concertim/packages`.

Obtaining these credentials is left as an exercise for the reader.

The following code snippets assume that these credentials are available in the
following environment variables.  If they are you can copy and paste the code
snippets.

* `AWS_ACCESS_KEY_ID` is your AWS access key id allowing downloading from
  the S3 bucket mentioned above.
* `AWS_SECRET_ACCESS_KEY` is your secret AWS access key allowing downloading
  from the S3 bucket mentioned above.
* `GH_TOKEN` is your GitHub oath token that allows access to the
  `alces-flight/concertim-ansible-playbook` repository.


## Install ansible

The ansible playbook has been tested against `ansible` version `5.10.0` other
versions of ansible may work but have not been tested.  Ansible `5.10.0` can
be installed with the following.

```bash
add-apt-repository --yes ppa:ansible/ansible
apt install --yes ansible
```


## Clone this git repository and checkout the correct tag

This git repository contains the ansible playbook to build and configure Alces
Concertim.  The playbook is intended to be ran on the Concertim machine itself.
To that end it needs to be downloaded to the Concertim machine.

This git repository is a private repository, so you will need to provide
credentials to clone it.

```bash
RELEASE_TAG="main"
cd /root
git clone https://${GH_TOKEN}@github.com/alces-flight/concertim-ansible-playbook.git
ln -s /root/concertim-ansible-playbook/contrib/dev/ansible /ansible-dev
cd /root/concertim-ansible-playbook
echo "Using tag ${RELEASE_TAG}"
git checkout --quiet ${RELEASE_TAG}
```

## Run the build playbook

Run the build playbook. You will need to ensure that your AWS credentials have
been gathered and exported.

```
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

```bash
ansible-playbook \
  --inventory /ansible-dev/inventory.ini \
  --extra-vars "aws_access_key_id=$AWS_ACCESS_KEY_ID aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
  /ansible-dev/build-playbook.yml
```