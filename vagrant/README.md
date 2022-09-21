# Developing and testing the ansible playbook with Vagrant

This directory contains a [Vagrantfile](Vagrantfile) that can be used to
develop and test the MIA ansible playbooks.

## Usage

### Automate running both playbooks on a Vagrant machine

This will build a new MIA machine automating an ansible run of both playbooks.

Before running this, the First Time Setup Wizard data must be configured, see
the [ansible README](/ansible/README.md) for details on how to do that.

```
cd vagrant/
vagrant destroy <HOST>
source scripts/prepare-env.sh
vagrant up <HOST>
```

If you wish to run the ansible playbooks separately, you can specify the
playbook to run, via the `ANSIBLE_PLAYBOOK` environment variable.

```
vagrant up --no-provision <HOST>
ANSIBLE_PLAYBOOK=build vagrant provision <HOST>
ANSIBLE_PLAYBOOK=configure vagrant provision <HOST>
```

### Bring up a base machine to acceptance test the ansible playbook

This allows testing the playbook with as little vagrant integration as
possible.  In particular, vagrant will not (1) install ansible; (2) mount the
`ansible` directory on the machine; or (3) run the ansible playbooks.

This should be done before cutting a new release.

```
cd vagrant/
vagrant destroy <HOST>
ACCEPTANCE=true vagrant up <HOST>
```

Then follow the instructions in the [ansible README](/ansible/README.md).
