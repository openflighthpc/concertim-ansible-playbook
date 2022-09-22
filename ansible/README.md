# Building and configuring a Concertim MIA

This directory contains two ansible playbooks to 1) build a vanilla MIA and 2)
configure a vanilla MIA.

## Prerequisites

* An Ubuntu 22.04 (jammy) or 20.04 (focal) machine that will become the MIA
  machine.
* Root access on that Ubuntu machine.

## Overview

The process can be 

1. Log into your Ubuntu machine and gain root access.
2. Gather GitHub and S3 credentials.
3. Install ansible and dependencies
4. Clone this git repository.
5. Configure the First Time Setup Wizard (FTSW) data.
6. Run the build and configure playbooks.

Steps 2 through 6 are described in more detail below.

## Gather GitHub and S3 credentials

You will need GitHub credentials to clone this repository and for the playbook
to download a tarfile from the `alces-flight/concertim-emma` GitHub
repository.

You will also need S3 credentials to allow the playbook to download packages
from S3.  The credentials need to allow downloading from
`s3://alces-flight/concertim/packages`.

Obtaining these credentials is left as an exercise for the reader.

The following code snippets assume that these credentials are available in the
following environment variables.  If you do this you can copy and past the
code snippets.

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

```
add-apt-repository --yes ppa:ansible/ansible
apt install --yes ansible
```


## Clone this git repository

This git repository contains the ansible playbook to build and configure a
Concertim MIA.  The playbook is intended to be ran on the MIA machine itself.
To that end it needs to be downloaded to the MIA machine.

This git repository is currently a private repository, so you will need to
provide credentials to clone it.

```
cd /root
git clone https://${GH_TOKEN}@github.com/alces-flight/concertim-bootstrap.git
ln -s /root/concertim-bootstrap/ansible /ansible
```

## Configure the First Time Setup Wizard data

The First Time Setup Wizard (FTSW) configures a vanilla appliance.  It uses
data contained in `appliance-config.tgz` and `setup-data.yml` files to do so.

Currently, there is example data that needs to be copied into place.
Eventually, there will be instructions on how to configure this data to suit.

```
cp -a  /ansible/roles/configure-vanilla/files/ftsw-example-data/ \
       /ansible/roles/configure-vanilla/files/tmp/ftsw-data
```


## Run the build and configure playbooks

Run the build playbook:

```
ansible-playbook \
  --inventory /ansible/inventory.ini \
  --extra-vars "github_token=$GH_TOKEN aws_access_key_id=$AWS_ACCESS_KEY_ID aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
  /ansible/build-playbook.yml
```

Run the configure playbook:

```
ansible-playbook --inventory /ansible/inventory.ini /ansible/configure-playbook.yml
```
