# Building Alces Concertim as a set of Docker containers

This directory contains scripts and configuration to use the ansible playbooks
to build Docker containers for running Alces Concertim.

The instructions here will work for version `0.1.1`, you're milage may vary
with other versions.

## Container overview

Currently, two docker containers are built.  One of these, `db`, is a
Postgresql image.  There are no known issues with this container.

The other container, `concertim` contains all other services that are required
for Concertim.  These include `nginx`, `memcached`, `ganglia`, and our three
concertim daemons.

The `db` container stores its data on a volume called `db-data`.  Currently,
this is the only volume that needs to be backed up.

## Build prerequisites

* A machine with `docker` and `docker-compose` installed.

## Build the images

To build the images, run the script `build-docker.sh` in this directory.  That
script will:

1. Check certain authentication details have been provided.
2. Run `docker-compose` to build the concertim Docker image.
3. Launch containers to migrate the concertim database.
4. Stop all started containers.

The database password is passed via an ansible secret.  A default is set in the
`docker/secrets/db_password.txt` file, you may wish to edit this file.

## Starting the docker images

The docker containers can be started by running the following in the root this
repository:

```
docker-compose \
  --file docker/docker-compose.yml \
  --project-directory . \
  up
```

## Limitations of the Concertim container

* It is much larger that we want; currently around 1.3GB.
* It runs multiple services that would probably be better in separate
  containers.
* Its services log to files, not standard output.
* It runs systemd, requiring the `--privileged` flat and read-only mounting of
  `/sys/fs/cgroup`.

These issues will be fixed in upcoming releases.
