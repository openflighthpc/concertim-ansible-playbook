# Building Alces Concertim as a set of Docker containers

This directory contains scripts and configuration to build Docker images and
containers from the Alces Concertim ansible playbooks.

The instructions here will work for the `0.1.3` release, your milage may
vary with other versions.

## Image and container overview

The [docker-compose.yml](docker-compose.yml) file defines four services
comprising the Concertim UI. Each service is built into its own image and it is
expected that a single container will be created from each. The services are:

* `metrics`: Provides an HTTP API for receiving and processing metrics.
* `visualisation`: Provides an HTTP API for reporting instances; and a web app
  for visualising the instances and their metrics.
* `proxy`: An nginx reverse proxy for the `metrics` and `visualisation`
  services.
* `db`: A postgresql database.

A number of volumes are created during the build process.  Two of these should
be backed up.

* `db-data`: contains the postgresql data including the racks and instances.
  This should be included in a data retention policy.
* `rrd-data`: contains the historial metrics as rrd file.  This should be
  included in a data retention policy.
* `static-content`: used to enable `proxy` to serve static assets.  This does
  not need to be backed up.
* `concertim-etc`: used to share some configuration between the services.  This
  may be removed in future versions.  This does not need to be backed up.

## Installation

Prerequisites:

* A machine with `docker` and `docker-compose` installed.
* GitHub credentials.

The steps for installing are briefly:

1. Clone the github repo.
2. Build the images.
3. Migrate the databases.
4. Start the containers.
5. Remove intermediate images.

These steps are described in more detail below.

### Clone the github repo

Clone this github repo to the build machine.  It is a private repo so you will
need access to your github credentials or a github token.  In the code snippet
below the repo is checked out to a folder named `concertim_ui`, doing this is
not necessary but will provide much nicer image and container names.

```
RELEASE_TAG="0.1.3"
git clone https://github.com/alces-flight/concertim-ansible-playbook.git concertim_ui
cd concertim_ui
git checkout --quiet ${RELEASE_TAG}
```

### Configuration

The default build binds two ports for HTTP and HTTPS traffic to the docker
host.  The defaults bind to the host ports `9080` and `9443` on interface
`127.0.0.1`.

If the default values are not suitable for your needs, you can change them by
editing them and restarting the containers. They are specified in the
[docker-compose.yml](docker-compose.yml#L37) file in the `services.proxy.ports`
section.  You can find documentation of the accepted format in the
[docker-compose port
documentation](https://docs.docker.com/compose/compose-file/compose-file-v3/#ports).

### Build the images

To build the images, run the script `build-images.sh` found in this directory.
That script will:

1. Check certain authentication details have been provided.
2. Run `docker-compose` to build the concertim Docker images.

```
docker/build-images.sh
```

### Migrate the databases

Before the containers are ready to be used, the database needs to be migrated.
This is done by running the script `migrate-database.sh` found in this
directory.  The script starts the `db` container, runs migration scripts in a
temporary `visualisation` container and then stops all containers.

```
docker/migrate-database.sh
```

### Start the containers

To start the containers, run the script `start-containers.sh` found in this
directory.  That script is a small wrapper around `docker-compose up`.

```
docker/start-containers.sh
```

### Stopping the containers

To stop the containers, run the script `stop-containers.sh` found in this
directory.  That script is a small wrapper around `docker-compose stop`.

```
docker/stop-containers.sh
```

### Remove intermediate images

The images are built from multi-stage Dockerfiles as a means of keeping their
size down.  Once the images have been built, the intermediate images, which can
be quite large, can be removed.  Doing so is left as an exercise to the reader.
