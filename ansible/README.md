# Building and configuring a Concertim MIA

This directory contains two ansible playbooks to 1) build a vanilla MIA and 2)
configure a vanilla MIA.

## Prerequisites

* An Ubuntu 22.04 (jammy) machine with at least 4GiB of memory and at least 2
  CPUs.  This machine will become the MIA.
* Root access on that Ubuntu machine.
* The Ubuntu machine needs to be configured to not use "Predictable Network
  Interface Names".  That is to use `ethX` naming instead of `enpXsY` style
  naming.

This repo ships with an ansible playbook that can be used to configure the
machine to use `ethX` style network names.

## Overview

The process can be 

1. Log into your Ubuntu machine and gain root access.
2. Gather GitHub and S3 credentials.
3. Install ansible and dependencies
4. Clone this git repository and checkout the correct tag.
5. Configure the First Time Setup Wizard (FTSW) data.
6. Optionally run the prep playbook to configure the network naming
   convention.
7. Run the build and configure playbooks.

Steps 2 through 7 are described in more detail below.

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

```bash
add-apt-repository --yes ppa:ansible/ansible
apt install --yes ansible
```


## Clone this git repository and checkout the correct tag

This git repository contains the ansible playbook to build and configure a
Concertim MIA.  The playbook is intended to be ran on the MIA machine itself.
To that end it needs to be downloaded to the MIA machine.

This git repository is currently a private repository, so you will need to
provide credentials to clone it.

```bash
cd /root
git clone https://${GH_TOKEN}@github.com/alces-flight/concertim-bootstrap.git
ln -s /root/concertim-bootstrap/ansible /ansible
```

Determine the correct tag to build from.  Unless you have reason not to you
should build from the most recent `revival-X` tag.  That tag can be determined
and checked out by running the following:

```bash
cd /root/concertim-bootstrap
NUM=$( git tag -l | grep '^revival-' | sed 's/^revival-//' | sort -h -r | head -n 1 )
echo "Using tag revival-${NUM}"
git checkout --quiet revival-${NUM}
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

## Optionally run the prep playbook to configure the network naming convention

Before the build and configure playbooks can be ran, the machine needs to be
configured to use `ethX` style network naming convention.  The following
snippet will detect if the playbook needs to be ran and inform you of the next
steps.

```bash
if [ -d /sys/class/net/eth0 ]; then
  echo
  echo "Your machine is correctly prepared."
  echo "Proceed to running the build and configure playbooks."
  echo
else
  echo
  echo "Your machine needs preparatory configuration."
  echo "Run the prep playbook"
  echo "Then reboot your machine and run the build and configure playbooks."
  echo "Make sure to add your credentials again."
  echo
fi
```

If the above snippet informs you to run the prep playbook run the following,
then reboot your machine.

```bash
ansible-playbook --inventory /ansible/inventory.ini /ansible/prep-playbook.yml
```

TODO: Simplify this section so that the playbook itself 1) detects if the
correct naming convention is in use; 2) informs the user of the next steps; 3)
automatically (perhaps requesting confirmation) reboots the machine only if
required.

## Run the build and configure playbooks

Run the build playbook:

```bash
if [ "$GH_TOKEN" == "" -o "$AWS_ACCESS_KEY_ID" == "" -o "$AWS_SECRET_ACCESS_KEY" == "" ] ; then
  echo "Some credentials are missing"
else
  ansible-playbook \
    --inventory /ansible/inventory.ini \
    --extra-vars "github_token=$GH_TOKEN aws_access_key_id=$AWS_ACCESS_KEY_ID aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
    /ansible/build-playbook.yml
fi
```

Run the configure playbook:

```bash
ansible-playbook --inventory /ansible/inventory.ini /ansible/configure-playbook.yml
```
