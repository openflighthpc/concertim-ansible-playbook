# Developing and testing the ansible playbook with Vagrant

This directory contains a [Vagrantfile](Vagrantfile) and associated scripts
that can be used to develop and test the MIA ansible playbooks.  The
`Vagrantfile` defines three boxes that can be built as a MIA, `command1`,
`command2`, and `command3`.

## Quick start

```sh
cd vagrant
./scripts/rebuild-box.sh command1
```

## Details

### Preparation

The boxes need some preparation before the build and configure playbooks can
be ran. This preparation is split into three Vagrant provisioners, `swap`,
`apt-upgrade` and `prep_playbook`.  These can be ran with:

```sh
cd vagrant/
vagrant up --provision-with swap,apt-upgrade BOX_NAME
vagrant provision --provision-with prep_playbook BOX_NAME
vagrant reload --force BOX_NAME
```

### Run the build and configure playbooks

This will build a new MIA machine automating an ansible run of both playbooks.


Before running this, the machine will need to have been prepared by following
the "Preparation" section and the First Time Setup Wizard data must be
configured, see the [ansible README](/ansible/README.md) for details on how to
do that.

```
cd vagrant/
source scripts/prepare-env.sh
vagrant reload --provision-with build_playbook,configure_playbook BOX_NAME
```

If you wish to run the ansible playbooks separately, you can specify the
playbook to run, via the `--provision-with` CLI argument.

### Bring up a base machine to acceptance test the ansible playbook

This allows testing the playbook with as little vagrant integration as
possible.  In particular, vagrant will not (1) install ansible; (2) mount the
`ansible` directory on the machine; or (3) run the ansible playbooks.

This should be done before cutting a new release.

```
cd vagrant/
vagrant destroy BOX_NAME
ACCEPTANCE=true vagrant up --provision-with swap,apt-upgrade BOX_NAME
```

Then follow the instructions in the [ansible README](/ansible/README.md).
