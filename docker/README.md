# Building Alces Concertim as a set of Docker containers

This directory contains scripts and configuration to build Docker images and
containers from the Alces Concertim ansible playbooks.

The instructions here will work for the current `main` branch, your milage may
vary with other versions.  You probably want to use the instructions for a
tagged release e.g., `0.1.4`.

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

* A machine with `docker` and `docker-compose-plugin` installed.
* GitHub credentials.
* AWS credentials.

The steps for installing are briefly:

1. Gather GitHub and S3 credentials
2. Clone the github repo.
3. Create encrypted AWS credentials file
4. Optionally, configure networking
5. Build the images.
6. Migrate the databases.
7. Start the containers.
8. Remove multi-stage "builder" images.

These steps are described in more detail below.

## Gather GitHub and S3 credentials

You will need GitHub credentials to clone this repository.

You will also need S3 credentials to allow the ansible playbook to download
packages from S3.  The credentials need to allow downloading from
`s3://alces-flight/concertim/packages`.

Obtaining these credentials is left as an exercise for the reader.

The following code snippets assume that the GitHub credential is available in
the `GH_TOKEN` environment variable.  If it is you can copy and paste the code
snippets.

### Clone the github repo

Clone this github repo to the build machine.  It is a private repo so you will
need access to your github credentials or a github token.  In the code snippet
below the repo is checked out to a folder named `concertim_ui`, doing this is
not necessary but will provide much nicer image and container names.

```
RELEASE_TAG="main"
git clone https://${GH_TOKEN}@github.com/alces-flight/concertim-ansible-playbook.git concertim_ui
cd concertim_ui
git checkout --quiet ${RELEASE_TAG}
```

### Create encrypted AWS credentials file

The Dockerfiles for the visualisation and metrics containers need AWS
credentials available to download pre-built source code from AWS.  These
credentials are passed to the ansible playbook using ansible-vault.  Doing this
instead of environment variables avoids the image's history from including the
credentials.

To create the encrypted file:

1. Create a `docker/secrets/vault-password.txt` password file.  It should
   contain a single line with the vault password of your choice.
2. Create the file `docker/secrets/aws-credenitals.yml` containing your AWS
   credentials.  There is an [example
   file](/docker/secrets/aws-credenitals.yml.example) to copy.
3. Run `ansible-vault encrypt` to encrypt the AWS credentials.
4. Remove the unencrypted credentials file.

The snippet below creates the password file with a random password; starts an
editor to allow you to edit `docker/secrets/aws-credentials.yml`; and then
encrypts the file.

```
touch docker/secrets/vault-password.txt
chmod 600 docker/secrets/vault-password.txt
date | sha256sum | cut -c 1-16 > docker/secrets/vault-password.txt
cp docker/secrets/aws-credentials.yml.example docker/secrets/aws-credentials.yml
$EDITOR docker/secrets/aws-credentials.yml
ansible-vault encrypt -v \
    --vault-password-file docker/secrets/vault-password.txt \
    --output docker/secrets/aws-credentials.yml.enc \
    docker/secrets/aws-credentials.yml
rm docker/secrets/aws-credentials.yml
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

Depending on how your docker host is configured you may also need to configure
the network MTU setting.  The default is set to 1400 which is suitable for the
expected production deployment.  If you run into network issues you may want to
stop the containers; change or remove this setting; restart the containers.

### Build the images

To build the images, run the script `build-images.sh` found in this directory.
That script will:

1. Check certain authentication details have been provided.
2. Run `docker compose` to build the concertim Docker images.

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
directory.  That script is a small wrapper around `docker compose up`.  The
script takes the same arguments as `docker compose up`; you will likely want to
pass `--detach`.

```
docker/start-containers.sh --detach
```

### Stopping the containers

To stop the containers, run the script `stop-containers.sh` found in this
directory.  That script is a small wrapper around `docker compose stop`.

```
docker/stop-containers.sh
```

### Remove unneeded multi-stage images

The images are built from multi-stage Dockerfiles as a means of keeping their
size down.  Once the images have been built, the now unneeded "builder" images,
should be removed if docker has not already done so automatically.  This can be
done with the following:

```
docker image ls --filter "label=com.alces-flight.concertim.role=builder"
docker image rm \$(docker image ls --filter "label=com.alces-flight.concertim.role=builder" -q)
```
