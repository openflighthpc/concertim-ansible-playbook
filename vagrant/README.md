# Developing and testing the ansible playbook with Vagrant

This directory contains a [Vagrantfile](Vagrantfile) and associated scripts
that can be used to develop and test the Concertim ansible playbooks and to
develop both of the Concertim apps:
[ct-visualisation-app](https://github.com/alces-flight/concertim-ct-visualisation-app)
and [metric reporting
daemon](https://github.com/alces-flight/concertim-metric-reporting-daemon).

The `Vagrantfile` defines two boxes that can be built as a Concertim machine,
`dev1` and `dev2`; it also defines a third box `asset-build` which is to be
used for asset building (see [asset-building.md](asset-building.md)).

## Quick start

```sh
cd vagrant
./scripts/rebuild-box.sh dev1
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


### Developing the Concertim apps

To develop the concertim apps first build either the `dev1` or `dev2` virtual
machine by following the instructions above, then configur

The vagrant machines can be used to develop the Concertim apps.  To do so:

1. Checkout the concertim source code to the expected location.
   ```
   mkdir -p ~/projects/concertim/src
   cd ~/projects/concertim/src
   git clone git@github.com:alces-flight/concertim-metric-reporting-daemon.git ct-metric-reporting-daemon
   git clone git@github.com:alces-flight/concertim-ct-visualisation-app.git ct-visualisation-app
   ```

2. Build a vagrant machine (either `dev1` or `dev2`).
   ```
   cd vagrant
   ./scripts/rebuild-box.sh dev1
   ```

3. SSH into the vagrant box and install the appliance-dev role
   ```
   cd vagrant
   vagrant ssh dev1
   sudo su -
   /vagrant/scripts/run-build-playbook.sh --tags appliance-dev --extra-vars want_dev_build=true
   ```

The `appliance-dev` will run the `ct-vis-app` and `ct-metrics` apps in separate
screen session.  They can be connected to with `screen -r ct-vis-app` and
`screen -r ct-metrics` respectively.

If the box is rebooted the screen sessions will need to be restarted.  SSH into
the box, gain root and run the following.

```
cd /opt/concertim/dev/ct-visualisation-app/core/
screen -dmS ct-vis-app ./bin/dev

cd /opt/concertim/dev/ct-metric-reporting-daemon
screen -dmS ct-metrics $(go env GOPATH)/bin/air -- --config-file config/config.dev.vm.yml
```
