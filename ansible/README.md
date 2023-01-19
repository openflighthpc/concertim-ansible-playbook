# Building and configuring a Concertim MIA

This directory contains ansible playbooks to build a vanilla MIA and configure
it.

The instructions here will work for version `revival-13`, you're milage may
vary with other versions.

## Prerequisites

* An Ubuntu 22.04 (jammy) machine with at least 4GiB of memory and at least 2
  CPUs.  This machine will become the MIA.
* Root access on that Ubuntu machine.
* The Ubuntu machine needs to be configured to not use "Predictable Network
  Interface Names".  That is to use `ethX` naming instead of `enpXsY` style
  naming.  This repo ships with an ansible playbook that can be used to
  configure the machine to use `ethX` style network names.

## Overview

The process is as follows.  Steps 2 through 7 are described in more detail
below.

1. Log into your Ubuntu machine and gain root access.
2. Gather GitHub and S3 credentials.
3. Install ansible and dependencies.
4. Clone this git repository and checkout the correct tag.
5. Configure the First Time Setup Wizard (FTSW) data.
6. Optionally run the prep playbook to configure the network naming
   convention.
7. Run the build and configure playbooks.

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
  `alces-flight/concertim-emma` repository.


## Install ansible

The ansible playbook has been tested against `ansible` version `5.10.0` other
versions of ansible may work but have not been tested.  Ansible `5.10.0` can
be installed with the following.

```bash
add-apt-repository --yes ppa:ansible/ansible
apt install --yes ansible
```


## Clone this git repository and checkout the correct tag

This git repository contains the ansible playbook to build and configure a
Concertim MIA.  The playbook is intended to be ran on the MIA machine itself.
To that end it needs to be downloaded to the MIA machine.

This git repository is a private repository, so you will need to provide
credentials to clone it.

```bash
RELEASE_TAG="revival-13"
cd /root
git clone https://${GH_TOKEN}@github.com/alces-flight/concertim-bootstrap.git
ln -s /root/concertim-bootstrap/ansible /ansible
cd /root/concertim-bootstrap
echo "Using tag ${RELEASE_TAG}"
git checkout --quiet ${RELEASE_TAG}
```

## Configure the First Time Setup Wizard data

The First Time Setup Wizard (FTSW) configures a vanilla appliance.  It uses
data contained in `appliance-config.tgz` and `setup-data.yml` files to do so.

Currently, there is example data that needs to be copied into place.
Eventually, there will be instructions on how to configure this data to suit.

```bash
cp -a  /ansible/roles/configure-vanilla/files/ftsw-example-data/ \
       /ansible/roles/configure-vanilla/files/tmp/ftsw-data
```

## Run the prep playbook to configure the network naming convention as needed

Before the build and configure playbooks can be ran, the machine needs to be
configured to use `ethX` style network naming convention.  Running the prep
playbook will preform that configuration if needed and inform you of the next
steps, which will be to either 1) reboot the machine and then run the build
and configure playbooks; or 2) move straight on to running the build and
configure playbooks.


```bash
ansible-playbook --inventory /ansible/inventory.ini /ansible/prep-playbook.yml
```

## Run the build and configure playbooks

Run the build playbook.

If you rebooted the machine after the above step, don't forget to ensure that
your credentials have been gathered and exported.

```
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
GH_TOKEN=...
```

You will also need to set the release tag that is being built.  This needs to
be consistent with the tag used in step 4.

```
RELEASE_TAG="revival-13"
```

```bash
ansible-playbook \
  --inventory /ansible/inventory.ini \
  --extra-vars "aws_access_key_id=$AWS_ACCESS_KEY_ID aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
  --extra-vars "release_tag=$RELEASE_TAG" \
  /ansible/build-playbook.yml
```

Run the configure playbook:

```bash
ansible-playbook --inventory /ansible/inventory.ini /ansible/configure-playbook.yml
```
