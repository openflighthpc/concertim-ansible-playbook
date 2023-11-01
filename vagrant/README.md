# Developing and testing the ansible playbook with Vagrant

This directory contains a [Vagrantfile](Vagrantfile) and associated scripts
that can be used to develop and test the Concertim ansible playbooks and to
develop both of the Concertim apps:
[ct-visualisation-app](https://github.com/alces-flight/concertim-ct-visualisation-app)
and [metric reporting
daemon](https://github.com/alces-flight/concertim-metric-reporting-daemon).

The `Vagrantfile` defines two boxes that can be built as a Concertim machine,
`dev1` and `dev2` (you only need to build one of these). It also defines a third box `asset-build` which is to be
used for asset building (see [asset-building.md](../ansible/asset-building.md)).

## Quick start

```sh
cd vagrant
./scripts/rebuild-box.sh dev1
```

## Details

### Preparation

#### Ensure assets can be downloaded from S3

- Update `release_tag` in `ansible/group_vars/all` to use a valid release tag, if there is not one uploaded for today.
E.g. `2023-08-07'.
- Obtain a GitHub auth token and export it to the environment variable `GH_TOKEN`
- Obtain S3 credentials that allow you to download packages from `s3://alces-flight/concertim/packages`.
Export these to the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- Alternatively, if you have already configured `aws` on your machine with the necessary credentials,
you can run `/scripts/prepare-env.sh` to export the key and id as defined in your aws setup. This will also
look for a file `../ansible/secrets.enc` (which you would need to manually create and populate) and export
a github token if present (defined in the secrets file as `GH_TOKEN=<my github token>`).

#### Box setup

The boxes need some preparation before the build playbook can be ran. This
preparation is split into the following Vagrant provisioners, `swap` and
`install_ansible`. These can be ran with:

```sh
cd vagrant/
vagrant up --no-provision BOX_NAME
vagrant provision --provision-with swap BOX_NAME
vagrant provision --provision-with install_ansible BOX_NAME
```

#### Run the build playbook

This will build a new Concertim machine automating an ansible run of the build
playbook. The two concertim apps will be launched in production mode.

```
cd vagrant/
source scripts/prepare-env.sh
vagrant provision --provision-with run_build_playbook BOX_NAME
```

## Bringing up a base machine to acceptance test the ansible playbook

This alternatively allows testing the playbook with as little vagrant integration as
possible.  In particular, vagrant will (1) not install ansible; (2) not mount
the `ansible` directory on the machine; and (3) not run the ansible playbooks.

This should be done before cutting a new release.

```
cd vagrant/
vagrant destroy BOX_NAME
ACCEPTANCE=true vagrant up --provision-with swap BOX_NAME
```

Then ssh into the VM and follow the instructions in the [ansible README](../ansible/README.md).

## Developing the Concertim apps

#### Concertim applications and folder structure

For development, this repo must be a sibling to a directory called `concertim`, containing the visualisation and metrics reporting repos.
For example, if you are using a parent directory called `projects` it would contain the directory
`concertim-ansible-playbook` and one called `concertim`, which can be created using:

   ```
   mkdir -p ~/projects/concertim/src
   cd ~/projects/concertim/src
   git clone git@github.com:alces-flight/concertim-metric-reporting-daemon.git ct-metric-reporting-daemon
   git clone git@github.com:alces-flight/concertim-ct-visualisation-app.git ct-visualisation-app
   ```

#### Virtual Machines

To develop the concertim apps first build either the `dev1` or `dev2` virtual
machine by following the instructions above, then configure it to run in development mode.

1. Configure concertim visualisation app:


   Ensure your local version of the visualisation app has an accessible `secret_key_base` set.
   This can be set using `EDITOR=nano rails credentials:edit` whilst in the visualisation app repo.
   You must also add active record encryption keys to this credentials file. You can obtain suitable keys for this
   by running (whist in the visualiser repo) `rails db:encryption:init` and add them to the credentials file manually,
   or automate this process by running `rake encryption:generate`.

2. In this repo, build a vagrant machine (either `dev1` or `dev2`), if not already built:

   ```
   cd vagrant
   ./scripts/rebuild-box.sh dev1
   ```

3. SSH into the vagrant box and install the appliance-dev role:
   ```
   cd vagrant
   vagrant ssh dev1
   sudo su -
   /vagrant/scripts/run-dev-playbook.sh --tags appliance-dev --extra-vars want_dev_build=true
   ```

The `appliance-dev` will run the `ct-vis-app` and `ct-metrics` apps in separate
screen session.  They can be connected to with `screen -r ct-vis-app` and
`screen -r ct-metrics` respectively.

If the box is rebooted the screen sessions will need to be restarted.  SSH into
the box, gain root and run the following.

```
cd /opt/concertim/dev/ct-visualisation-app/
screen -dmS ct-vis-app ./bin/dev

cd /opt/concertim/dev/ct-metric-reporting-daemon
screen -dmS ct-metrics $(go env GOPATH)/bin/air -- --config-file config/config.dev.yml
```

If you need to run data migrations or access the rails console, these should be done whilst in the directory
`/opt/concertim/dev/ct-visualisation-app/` (in the virtual machine).
