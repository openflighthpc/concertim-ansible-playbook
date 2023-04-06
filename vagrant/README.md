# Developing and testing the ansible playbook with Vagrant

This directory contains a [Vagrantfile](Vagrantfile) and associated scripts
that can be used to develop and test the Concertim ansible playbooks.  The
`Vagrantfile` defines two boxes that can be built as a Concertim machine,
`dev1` and `dev2`; it also defines a third box `asset-build` which is to be
used for asset building.

## Quick start

```sh
cd vagrant
./scripts/rebuild-box.sh command1
```

## Details

### Preparation

The boxes need some preparation before the build playbook can be ran. This
preparation is split into the following Vagrant provisioners, `swap` and
`install_ansible`.  These can be ran with:

```sh
cd vagrant/
vagrant up --no-provision BOX_NAME
vagrant provision --provision-with swap BOX_NAME
vagrant provision --provision-with install_ansible BOX_NAME
```

### Run the build playbook

This will build a new Concertim machine automating an ansible run of the build
playbook.

```
cd vagrant/
source scripts/prepare-env.sh
vagrant provision --provision-with run_build_playbook BOX_NAME
```

### Bring up a base machine to acceptance test the ansible playbook

This allows testing the playbook with as little vagrant integration as
possible.  In particular, vagrant will (1) not install ansible; (2) not mount
the `ansible` directory on the machine; and (3) not run the ansible playbooks.

This should be done before cutting a new release.

```
cd vagrant/
vagrant destroy BOX_NAME
ACCEPTANCE=true vagrant up --provision-with swap BOX_NAME
```

Then follow the instructions in the [ansible README](/ansible/README.md).

## Asset building

TBD: Improve this section.

The ansible build playbook expects certain assets to be available for it in S3.
These assets are built and uploaded to S3 by running the
`package-assets-playbook.yml`.  Typically, this is done on the `asset-build`
vagrant box.

On your laptop run the following:

```sh
cd vagrant/
vagrant up asset-build
vagrant ssh asset-build
```

Once SSHd into the vagrant box, gain root with `sudo su -` and then run the
following:

```
GH_TOKEN=...
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

```bash
ansible-playbook /ansible/package-assets-playbook.yml \
  --inventory /ansible/inventory.ini \
  --extra-vars "gh_token=$GH_TOKEN" \
  --extra-vars "aws_access_key_id=$AWS_ACCESS_KEY_ID aws_secret_access_key=$AWS_SECRET_ACCESS_KEY"
```
