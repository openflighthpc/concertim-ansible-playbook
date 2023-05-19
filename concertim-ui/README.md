# Deploying Alces Concertim as a set of Docker containers

This directory contains configuration for deploying Alces Concertim as a set of
docker containers using a `docker-compose.yml` file.

The instructions here will work for the current `main` branch, your milage may
vary with other versions.  You probably want to use the instructions for a
tagged release e.g., `0.1.3`.

## Image and container overview

The [docker-compose.yml](docker-compose.yml) file defines four services
comprising the Concertim UI. It is expected that a single container will be
created from each. The services are:

* `metrics`: Provides an HTTP API for receiving and processing metrics.
* `visualisation`: Provides an HTTP API for reporting instances; and a web app
  for visualising the instances and their metrics.
* `proxy`: An nginx reverse proxy for the `metrics` and `visualisation`
  services.
* `db`: A postgresql database.

A number of volumes are used by the images.  Two of these should be backed up.

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
* Concertim docker registry credentials.
* Docker configured to accept `registry.docker.concertim.alces-flight.com` as
  an insecure registry.

The steps for installing are briefly:

1. Gather credentials for the Concertim docker registry
   `registry.docker.concertim.alces-flight.com`.
2. Clone this directory of this github repo.
3. Login to the concertim docker registry.
4. Optionally, configure networking.
5. Migrate the databases.
6. Start the containers.


## Configure docker to accept registry.docker.concertim.alces-flight.com as an insecure registry

Currently, the Concertim docker registry lacks a public IP address, DNS entry
and uses a self-signed certificate.  All of these issues will be addressed
soon, but for now docker needs to be configured to accept the registry as
insecure.

Add the following entry to /etc/hosts

```
10.151.15.51 registry.docker.concertim.alces-flight.com
```

Configure docker to accept insecure SSL certificates for this site.  Create the file `/etc/docker/daemon.json`

```
$ cat /etc/docker/daemon.json 
{
  "insecure-registries": ["registry.docker.concertim.alces-flight.com:443"]
}
```

Download the SSL cert and save to the right location.

```
sudo mkdir -p /etc/docker/certs.d/registry.docker.concertim.alces-flight.com
(echo | openssl s_client -showcerts -connect registry.docker.concertim.alces-flight.com:443) | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' | sudo tee /etc/docker/certs.d/registry.docker.concertim.alces-flight.com/docker_registry.crt
```

Restart the docker daemon

```
sudo systemctl restart docker
```

## Gather GitHub and Concertim docker registry credentials

You will need GitHub credentials to clone this repository.

You will also need credentials for the Concertim docker registry to download
the docker images.

Obtaining these credentials is left as an exercise for the reader.

The following code snippets assume that the GitHub credential is available in
the `GH_TOKEN` environment variable.  If it is you can copy and paste the code
snippets.

### Clone the github repo

Clone this directory of this github repo to the build machine.  It is a private
repo so you will need access to your github credentials or a github token.

```
RELEASE_TAG="main"
git clone -n --depth=1 --filter=tree:0 \
  https://${GH_TOKEN}@github.com/alces-flight/concertim-ansible-playbook.git
cd concertim-ansible-playbook
git sparse-checkout set --no-cone docker
git checkout --quiet ${RELEASE_TAG}
```

### Login to the concertim docker registry

```
docker login registry.docker.concertim.alces-flight.com
```


### Configuration

The default build binds two ports for HTTP and HTTPS traffic to the docker
host.  The defaults bind to the host ports `80` and `443` on interface
`0.0.0.0`.

If the default values are not suitable for your needs, you can change them by
editing them and restarting the containers. They are specified in the
[docker-compose.yml](docker-compose.yml#L30) file in the `services.proxy.ports`
section.  You can find documentation of the accepted format in the
[docker-compose port
documentation](https://docs.docker.com/compose/compose-file/compose-file-v3/#ports).

Depending on how your docker host is configured you may also need to configure
the network MTU setting.  The default is set to 1400 which is suitable for the
expected production deployment.  If you run into network issues you may want to
stop the containers; change or remove this setting; restart the containers.


### Migrate the databases

Before the containers are ready to be used, the database needs to be migrated.
This is done by running the following commands.

```
docker compose up db --detach
docker compose run --rm --user www-data -e RAILS_ENV=production visualisation /bin/bash -c 'cd /opt/concertim/opt/ct-visualisation-app/core && bin/rails db:create --trace'
docker compose run --rm --user www-data -e RAILS_ENV=production visualisation /bin/bash -c 'cd /opt/concertim/opt/ct-visualisation-app/core && bin/rails db:migrate --trace'
```

If the last few lines are:

```
I, [2023-05-19T00:33:44.295125 #1]  INFO -- : Migrating to RemoveDefaultOperatorUsers (20230510141319)
== 20230510141319 RemoveDefaultOperatorUsers: migrating =======================
-- Removing user:3(operator_one Operator One)
-- Removing user:4(operator_two Operator Two)
== 20230510141319 RemoveDefaultOperatorUsers: migrated (0.0999s) ==============
```

The command has worked.

You may wish to stop the `db` container at this point.


### Start the containers

To start the containers, run `docker compose up`. You will likely want to
provide the `--detach` option.

```
docker compose up --detach
```

### Stopping the containers

To stop the containers, run `docker compose stop`.

```
docker compose stop
```
