# Asset building

The ansible `build-playbook.yml` playbook requires certain assets to be
available for it in S3.  These assets are built by running the
`package-assets-playbook.yml`.

## Prerequisites

* An Ubuntu 22.04 (jammy) machine with at least 3GiB of memory and at least 2
  CPUs.  This machine will become the Alces Concertim machine.
* Root access on that Ubuntu machine.

The [Vagrantfile](/contrib/dev/vagrant/Vagrantfile) contains an `asset-build` box which can
be used for this.

## Overview

The process is slightly different depending on whether the assets are being
built for a release or as part of testing a development version of the ansible
playbooks.

To build release assets:

1. Log into your Ubuntu machine and gain root access.
2. Gather GitHub and S3 credentials.
3. Install ansible and dependencies.
4. Create a new release tag.
5. Clone this git repository and checkout the correct tag.
6. Run the package assets playbook.

To build dev assets:

1. Log into your Ubuntu machine and gain root access.
2. Gather GitHub and S3 credentials.
3. Install ansible and dependencies.
4. Clone this git repository and checkout the main branch.
5. Run the package assets playbook.

## Asset build vagrant box

The [Vagrantfile](/contrib/dev/vagrant/Vagrantfile) contains an `asset-build` box which can
be used to build the assets.

If building dev assets bring the box up with `vagrant up asset-build`.  The
ansible scripts will then be available on that box at `/ansible` skipping the
need to clone the git repository.

If building release assets bring the box up with `ACCEPTANCE=true vagrant up
asset-build`.  The local copy of the ansible scripts will not be available. The
git repository will need cloning, isolating the build from any local changes.


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

## Create a new release tag.

1. Edit the `release_tag` variable found in
   [ansible/group_vars/all](group_vars/all) to the new tag, say,
   v0.1.0.
2. Commit the change; create a git tag named the same and push.
3. Edit the `release_tag` back to its original `dev-...` value; commit and
   push.

## Clone this git repository and checkout the correct tag

This git repository contains the ansible playbook to build and configure Alces
Concertim.  The playbook is intended to be ran on the Concertim machine itself.
To that end it needs to be downloaded to the Concertim machine.

This git repository is a private repository, so you will need to provide
credentials to clone it.

If building dev assets, set `RELEASE_TAG` to `main`.  Otherwise set it to the
tag you created above.

```bash
RELEASE_TAG="main"  # or "v0.1.0"
```

```bash
cd /root
git clone https://${GH_TOKEN}@github.com/alces-flight/concertim-ansible-playbook.git
ln -s /root/concertim-ansible-playbook/ansible /ansible
cd /root/concertim-ansible-playbook
echo "Using tag ${RELEASE_TAG}"
git checkout --quiet ${RELEASE_TAG}
```

## Run the package assets playbook

Run the package assets playbook. You will need to ensure that your AWS
credentials and GitHub have been gathered and exported.

```
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
GH_TOKEN=...
```

```bash
ansible-playbook /ansible/package-assets-playbook.yml \
  --inventory /ansible/inventory.ini \
  --extra-vars "gh_token=$GH_TOKEN" \
  --extra-vars "aws_access_key_id=$AWS_ACCESS_KEY_ID aws_secret_access_key=$AWS_SECRET_ACCESS_KEY"
```

If everything builds OK, the playbook will print a dry run of the S3 upload. If
you are building dev assets make sure that the assets are going to be uploaded
with a `dev-...` prefix.

If that looks OK upload the assets by running the following:

```bash
ansible-playbook /ansible/package-assets-playbook.yml \
  --inventory /ansible/inventory.ini \
  --extra-vars "gh_token=$GH_TOKEN" \
  --extra-vars "aws_access_key_id=$AWS_ACCESS_KEY_ID aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
  --extra-vars "dryrun=no" \
  --tags upload
```
