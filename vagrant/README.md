# Developing and testing the ansible playbook with Vagrant

This directory contains a [Vagrantfile](Vagrantfile) and associated scripts
that can be used to develop and test the Concertim ansible playbooks.  The
`Vagrantfile` defines three boxes that can be built as a Concertim machine,
`command1`, `command2`, and `command3`.

## Quick start

```sh
cd vagrant
./scripts/rebuild-box.sh command1
```

## Details

### Preparation

The boxes need some preparation before the build playbook can be ran. This
preparation is split into the following Vagrant provisioners, `swap`,
`install_ansible`, `run_prep_playbook`.  These can be ran with:

```sh
cd vagrant/
vagrant up --no-provision BOX_NAME
vagrant provision --provision-with swap BOX_NAME
vagrant provision --provision-with install_ansible BOX_NAME
vagrant provision --provision-with run_prep_playbook BOX_NAME
vagrant reload --force BOX_NAME
```

### Run the build playbook

This will build a new Concertim machine automating an ansible run of the build
playbook.

Before running this, the machine will need to have been prepared by following
the "Preparation" section, see the [ansible README](/ansible/README.md) for
details on how to do that.

```
cd vagrant/
source scripts/prepare-env.sh
vagrant reload --force BOX_NAME
vagrant provision --provision-with run_build_playbook BOX_NAME
```

### Bring up a base machine to acceptance test the ansible playbook

This allows testing the playbook with as little vagrant integration as
possible.  In particular, vagrant will not (1) install ansible; (2) mount the
`ansible` directory on the machine; or (3) run the ansible playbooks.

This should be done before cutting a new release.

```
cd vagrant/
vagrant destroy BOX_NAME
ACCEPTANCE=true vagrant up --provision-with swap BOX_NAME
```

Then follow the instructions in the [ansible README](/ansible/README.md).
