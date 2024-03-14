# Deploying Alces Concertim as a set of Docker containers

## Quick start

* Configure required OpenStack users and roles.  See https://github.com/alces-flight/concertim-openstack-service/tree/master#openstack for details.
* Ensure the target machine has `ansible-playbook` `>= 2.10.8`, `docker` `>=
  24.0.7`, `docker-compose-plugin` `>= v2.21.0`, and the Python3 Docker libraries
  (`python3-docker` on Ubuntu).
* Make a GitHub token available in the `GH_TOKEN` environment variable.
* Gain a root shell on the target machine.
* Clone the github repo to `/opt/concertim/ansible-playbook` and checkout the `main` branch.
  ```bash
  RELEASE_TAG="main"
  mkdir -p /opt/concertim/opt
  cd /opt/concertim/opt
  git clone -n --depth=1 --filter=tree:0 --no-single-branch \
    https://${GH_TOKEN}@github.com/alces-flight/concertim-ansible-playbook.git ansible-playbook
  cd /opt/concertim/opt/ansible-playbook
  git checkout --quiet ${RELEASE_TAG}
  ```
* Edit the `globals.yaml` file to configure which components are installed, which host network ports the services are bound to, and optionally which hostnames the concertim UI will be accessed over.
  ```bash
  cd /opt/concertim/opt/ansible-playbook/ansible
  $EDITOR etc/globals.yaml
  ```
* Run the ansible playbook to install the Concertim services on `localhost`.
  ```bash
  cd /opt/concertim/opt/ansible-playbook/ansible
  ansible-playbook \
    --inventory inventory.ini \
    --extra-vars "gh_token=$GH_TOKEN" \
    --extra-vars @etc/globals.yaml \
    playbook.yml
  ```

If the killbill service was installed, you will also need to:

* Create a KAUI tenant and upload a catalog.  See https://github.com/alces-flight/concertim-openstack-service/blob/master/docs/killbill_basic.md#configuration-of-kaui for details.
* Edit the concertim openstack service configuration file with the Kill Bill API key and API secret.

If the concertim openstack service components were installed, you will also need to:

* Edit the concertim openstack service configuration file.  See https://github.com/alces-flight/concertim-openstack-service/tree/master#configuration for details.
  ```bash
  $EDITOR /opt/concertim/etc/openstack-service/config.yaml
  ```
* Restart the openstack services to pick up the configuration changes
  ```bash
  cd /opt/concertim/opt/docker
  docker compose restart
  ```

## Deployment in more detail

The ansible playbook will deploy the Concertim services as a set of Docker containers.
By default, they will be installed on the machine that runs the playbook.
All of the artefacts installed can be found under the `/opt/concertim/` directory structure.
More details on the directory structure can be found in the [container overview](/docs/container-overview.md).

The steps for installing are briefly:

1. Configure OpenStack with required users and roles.
2. Gather your GitHub credentials.
3. Clone this github repo (https://github.com/alces-flight/concertim-ansible-playbook).
4. Optionally, edit the global settings.
5. Run the ansible playbook.
6. Configure Kill Bill / KAUI.
7. Edit the concertim openstack service configuration.
8. Restart the containers.

### Configure OpenStack with users and roles

Concertim expects certain users and roles to be configured in OpenStack.
Currently, this needs to be done outside of this installation mechanism.
See https://github.com/alces-flight/concertim-openstack-service/tree/master#openstack for details of the users and roles to configure.

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
If you wish to install a released version, you should follow the instructions for that release.

```bash
RELEASE_TAG="main"
mkdir -p /opt/concertim/opt
cd /opt/concertim/opt
git clone -n --depth=1 --filter=tree:0 --no-single-branch \
  https://${GH_TOKEN}@github.com/alces-flight/concertim-ansible-playbook.git ansible-playbook
cd /opt/concertim/opt/ansible-playbook
git checkout --quiet ${RELEASE_TAG}
```

### Edit the globals.yaml file

By default, the concertim, cluster builder and concertim openstack service
components will all be installed.  If you wish to install only some of these,
edit the `etc/globals.yaml` file and change the `enable_*` settings
appropriately.

Some concertim services are exposed to the host network.
The [etc/globals.yaml](/ansible/etc/globals.yaml) file can be used
to configure which host interfaces and ports they are bound to.
The default settings should work but may not be suitable for your needs.
You can change these setting by editing the `etc/globals.yaml` file.

```bash
cd /opt/concertim/opt/ansible-playbook/ansible
$EDITOR etc/globals.yaml
```

To enable live updates on the interactive rack view, Concertim needs to be
configured with the hostname that is used to access the Concertim UI.  If this
is not provided, it will default to the fully qualified hostname of the machine
concertim is installed on.  A list of alternative hostnames can be provided by
editing the `access_hostnames` variable in etc/globals.yaml.

### Run the playbook

The playbook will clone additional private github repositories.
You will need to have a github token available in the `GH_TOKEN` environment variable.

```bash
cd /opt/concertim/opt/ansible-playbook/ansible
ansible-playbook \
  --inventory inventory.ini \
  --extra-vars "gh_token=$GH_TOKEN" \
  --extra-vars @etc/globals.yaml \
  playbook.yml
```


### Configure Kill Bill and KAUI

If Kill Bill has been installed, you will need to create a KAUI tenant and upload a catalog.
You can login to KAUI at `http://my.host:49090` where `my.host` is the hostname of the machine this playbook was ran on.
The default username and password are available in `/opt/concertim/etc/openstack-service/config.yaml`.

Once logged in create the tenant using the `apikey` and `apisecret` available in `/opt/concertim/etc/openstack-service/config.yaml`.
If you use a different API key and secret, be sure to update the `apikey` and `apisecret` in `/opt/concertim/etc/openstack-service/config.yaml`.

Once the tenant is created, a catalog needs to be created.  Details of how to do this are given at https://github.com/alces-flight/concertim-openstack-service/blob/master/docs/killbill_basic.md#configuration-of-kaui


### Edit the concertim openstack service configuration

After the playbook has ran, the concertim openstack service configuration will have been installed.
You should now configure this appropriately for your environment and restart the containers.

```bash
$EDITOR /opt/concertim/etc/openstack-service/config.yaml
```

Once your configuration is correct, restart the containers to have them pick up
the changes to the configuration.

```bash
cd /opt/concertim/opt/docker
docker compose restart
```


## Container overview and controlling

For details on how to control the containers see the [starting and stopping instructions](/docs/controlling.md).
For details of the images, containers and volumes see the [container overview](/docs/container-overview.md).
