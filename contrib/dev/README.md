# Creating a development environment for developing the Concertim Services

This directory contains an ansible playbook and a Vagrantfile that can be used
to build a development environment for development of the Metric Reporting Daemon
and Visualisation App components.

## Quick start

1. Checkout the concertim repositories in the expected locations.
   ```sh
   mkdir -p ~/projects/concertim/src
   cd ~/projects/concertim
   git clone git@github.com:alces-flight/concertim-ansible-playbook.git
   cd ~/projects/concertim/src
   git clone git@github.com:alces-flight/concertim-metric-reporting-daemon.git ct-metric-reporting-daemon
   git clone git@github.com:alces-flight/concertim-ct-visualisation-app.git ct-visualisation-app
   ```

2. Build the vagrant machine `dev2`:
   ```sh
   cd contrib/dev/vagrant
   BUILD_ENV=dev ./scripts/rebuild-box.sh dev2
   ```

You now have a working development environment for metric reporting daemon and
visualisation app.

You can access the visualisation app at https://localhost:9445.

You can edit the code for visualisation app and metric reporting daemon on your
laptop (e.g., `$EDITOR ~/projects/concertim/src/ct-visualisation-app/README.md`)
and the changes will be picked up by the servers running on the vagrant
machine.

## Accessing and managing the dev servers

After the vagrant machine has been (re)built, the metric reporting daemon and
visualisation app will be running on the Vagrant machine in two screen
sessions: `ct-vis-app` and `ct-metrics`.  They can be connected to with `screen
-r ct-vis-app` and `screen -r ct-metrics` respectively.

If the box is rebooted the screen sessions will need to be restarted.  SSH into
the box, gain root and run the following.

```sh
cd /opt/concertim/dev/ct-visualisation-app/
screen -dmS ct-vis-app ./bin/dev

cd /opt/concertim/dev/ct-metric-reporting-daemon
screen -dmS ct-metrics $(go env GOPATH)/bin/air -- --config-file config/config.dev.yml
```

If you need to run data migrations or access the rails console, these should be
done whilst in the directory `/opt/concertim/dev/ct-visualisation-app/` (in the
virtual machine).


## Developing without using a vagrant machine

If you wish to develop without using the provided Vagrantfile, you can follow
the [instructions for the development ansible playbook](ansible/README.md).

## Simultaneous development of concertim ansible playbook and concertim components

The [Vagrantfile](vagrant/Vagrantfile) defines two identical vagrant boxes
`dev1` and `dev2`.  The documentation assumes that `dev1` is used to develop
the concertim ansible playbook itself, whilst `dev2` is used to develop the
concertim applications.  However, that is entirely convention and you can use
them as you wish.
