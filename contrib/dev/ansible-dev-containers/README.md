# Configuring the Concertim containers to create a development environment for Concertim Services

This directory contains an ansible playbook to configure the production
installation of the docker containers to one that is suitable for development.
All of the concertim containers will be configured for development including
live reloading of source code changes where supported.

This is an alternative development environment to that found in
[contrib/dev/ansible/](contrib/dev/ansible/).  The one there installs only
Visualisation and Metric Reporting Daemon.  This installs all of our components
and is intended to replace the other.

If you are looking for a production deployment of Concertim, see the
[these instructions](/ansible/README.md), for details on how to build
Concertim as a set of Docker containers.

The instructions here will work for the current `chore/alternate-dev-env`
branch, your milage may vary with other versions.

## Overview

1. Log into the machine on which the docker containers are to be installed and gain root access.
2. Install ansible and dependencies.
3. Clone this git repository and checkout the correct tag.
4. Run the production installation playbook.
5. Run the dev containers playbook.
6. Post installation configuration

## Login to machine and gain root access

You can install the docker containers on your laptop, but as the playbooks are
currently designed to be ran as root you might prefer to use a virtual machine.
If so, you can use a vagrant machine defined in
[contrib/dev/vagrant/](/contrib/dev/vagrant/).  However, use of a virtual
machine is optional.

```sh
cd contrib/dev/vagrant
BUILD_ENV=prod ./scripts/rebuild-box.sh dev1
```

## Install ansible, docker and docker compose

If using the Vagrant machine and `rebuild-box.sh` script above, this will have
already been done.  Otherwise install ansible, docker and docker compose
plugin.  See [ansible/README.md](/ansible/README.md) for details on specific
versions.


## Run the production installation playbook

On the virtual machine run the following:

```sh
/vagrant/scripts/run-prod-playbook.sh
```

This will install the docker containers in a configuration suitable for production use.


## Prevent visualisation from serving the pre-compiled assets

Edit the docker-compose.yml file and remove the `static-content` volume from
the `visualisation` service.  Without this, new assets may not be picked up by
the development server.

```diff
--- docker-compose.yml.orig	2024-03-11 14:37:48.370604710 +0000
+++ docker-compose.yml	2024-03-11 14:38:07.786597337 +0000
@@ -4,7 +4,7 @@
   visualisation:
     image: concertim-visualisation-app:latest
     volumes:
-      - static-content:/opt/concertim/opt/ct-visualisation-app/public/
+      # - static-content:/opt/concertim/opt/ct-visualisation-app/public/
       - type: bind
         source: "/opt/concertim/etc"
         target: "/opt/concertim/etc"
```


## Run the dev containers playbook.

On the virtual machine run the following:

```sh
/vagrant/scripts/install-dev-containers.sh
```

This will configure the docker containers suitable for development use.


## Post installation configuration

### Copy across your editor, git and other configuration

This is left as an exercise for the reader, but you probably have lots of
configuration to copy across to make the vagrant machine home.


### Edit the source files

You can find the source code for the various concertim components at
`/opt/concertim/opt`.  Editing the source files will result in the changes
being picked up immediately for the visualisation, metric reporting daemon and
cluster builder components.  Live-reloading is not yet implemented for the
middleware services.
