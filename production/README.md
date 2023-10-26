# Deploying Alces Concertim as a set of Docker containers

This directory contains an ansible playbook that will deploy the Alces
Concertim services as a set of Docker containers.

## Quick start

* Ensure the target machine has `ansible-playbook`, `docker` and
  `docker-compose-plugin` installed.
* Make a GitHub token available in the `GH_TOKEN` environment variable.
* Gain a root shell on the target machine.
* Clone the github repo to `/opt/concertim/ansible-playbook` and checkout the `feat/automated-build-of-all-components` branch.
  ```bash
  RELEASE_TAG="feat/automated-build-of-all-components"
  mkdir /opt/concertim/
  cd /opt/concertim/
  git clone -n --depth=1 --filter=tree:0 \
    https://${GH_TOKEN}@github.com/alces-flight/concertim-ansible-playbook.git ansible-playbook
  git sparse-checkout set --no-cone production
  git checkout --quiet ${RELEASE_TAG}
  ```
* Edit the `globals.yaml` file to configure which host network ports are bound to.
  ```bash
  cd /opt/concertim/ansible-playbook
  $EDITOR etc/globals.yaml
  ```
* Run the ansible playbook to install the Concertim services on `localhost`.
  ```bash
  cd /opt/concertim/ansible-playbook
  ansible-playbook \
    --inventory inventory.ini \
    --extra-vars "gh_token=$GH_TOKEN" \
    --extra-vars @etc/globals.yaml \
    playbook.yml
  ```

## Deployment in more detail

The ansible playbook will deploy the Concertim services as a set of Docker containers.
By default, they will be installed on the machine that runs the playbook.
All of the artefacts installed can be found under the `/opt/concertim/` directory structure.
More details on the directory structure can be found XXX.

The steps for installing are briefly:

1. Gather your GitHub credentials.
2. Clone this github repo (https://github.com/alces-flight/concertim-ansible-playbook).
3. Run the ansible playbook.

### Gather GitHub credentials

You will need GitHub credentials to clone the Concertim repositories.
The credentials will need to be able to clone the Concertim repositories from
the `alces-flight` organisation.
Obtaining these credentials is left as an exercise for the reader.

The following code snippets assume that the GitHub credentials are available in
the `GH_TOKEN` environment variable.  If it is you can copy and paste the code
snippets.

### Clone the github repo

Clone this github repo to the machine that will run the ansible playbook.
The repo is a private repo,
so you will need to have a github token available in the `GH_TOKEN` environment variable.
The following snippet will clone the `main` branch of the repo to `/opt/concertim/ansible-playbook`, 
it is also careful to avoid downloading more data than is needed.
If you wish to use a branch other than `main`, change the `RELEASE_TAG` appropriately.

```bash
RELEASE_TAG="main"
mkdir /opt/concertim/
cd /opt/concertim/
git clone -n --depth=1 --filter=tree:0 \
  https://${GH_TOKEN}@github.com/alces-flight/concertim-ansible-playbook.git ansible-playbook
git sparse-checkout set --no-cone production
git checkout --quiet ${RELEASE_TAG}
```

### Edit the globals.yaml file

Some concertim services are exposed to the host network.
The [etc/globals.yaml](etc/globals.yaml) file can be used
to configure which host ports and interfaces are bound to.
The default settings should work but may not be suitable for your needs.

```bash
cd /opt/concertim/ansible-playbook
$EDITOR etc/globals.yaml
```

### Run the playbook

The playbook will clone additional private github repositories,
so you will need to have a github token available in the `GH_TOKEN` environment variable.

```bash
cd /opt/concertim/ansible-playbook
ansible-playbook \
  --inventory inventory.ini \
  --extra-vars "gh_token=$GH_TOKEN" \
  --extra-vars @etc/globals.yaml \
  playbook.yml
```

## Image and container overview

Four services comprising the Concertim UI are created by the playbook.
The services are:

* `metrics`: Provides an HTTP API for receiving and processing metrics.
* `visualisation`: Provides an HTTP API for reporting racks and instances; and a web app
  for visualising the instances and their metrics.
* `proxy`: An nginx reverse proxy for the `metrics` and `visualisation`
  services.
* `db`: A postgresql database.


## Docker volumes

A number of volumes are used by the images.  Two of these should be included in
your sites retention policy.

* `db-data`: contains the postgresql data including the racks and instances.
  This should be included in a data retention policy.
* `rrd-data`: contains the historial metrics as rrd file.  This should be
  included in a data retention policy.
* `static-content`: used to enable `proxy` to serve static assets.  This does
  not need to be backed up.


## Directory structure on host machine

After the playbook has ran a number of files and directories will exist under `/opt/concertim`.
The most important are:

* `/opt/concertim/etc/` configuration files for the Concertim services.  The
Concertim services can be configured by editing these files and restarting the
appropriate service.
* `/opt/concertim/opt/docker/docker-compose.yml` the docker compose configuration for the concertim services.
* `/opt/concertim/opt/docker/secrets` credentials for the Concertim services.  These need to remain here, but you should be careful to ensure that the directory and file permissions are secure.


Other directories include:

* `/opt/concertim/opt/ansible-playbook/` the ansible playbook that was cloned earlier in these instructions.
* `/opt/concertim/opt/visualisation-app/` the source code for Concertim Visualisation App.  It is used to build a docker image.
* `/opt/concertim/opt/metric-reporting-daemon/` the source code for Concertim Metric Reporting Daemon.  It is used to build a docker image.
* `/opt/concertim/opt/proxy/` configuration for building an nginx reverse proxy docker image.


## Starting and stopping the Concertim services

After the playbook has ran all of the Concertim services are running.

The services can be stopped by running:

```bash
cd /opt/concertim/opt/docker
docker compose stop
```

The services can be started by running:

```bash
cd /opt/concertim/opt/docker
docker compose start
```

A single service can be restarted by running the following,
where `<service>` is one of `metrics`, `visualisation`, `proxy`, `db`:

```bash
cd /opt/concertim/opt/docker
docker compose restart <service>
```

## Configuring a Concertim service

To configure the `metrics` service:

1. Edit the file `/opt/concertim/etc/metric-reporting-daemon.yml`.
2. Restart the service see [Starting and stopping services](#starting-and-stopping-the-concertim-services).

To configure the `visualisation` service:

1. Log in to the visualisation web app as the `admin` user.
2. Navigate to "Cloud environment".
3. Enter the configuration details and click "Create" (or "Update").

Configuration of the `proxy` and `db` services is not currently supported.
