# Overview of the Concertim containers

## Image and container overview

A number of containers comprising Concertim are created by the playbook.
They are managed by a docker compose file located at `/opt/concertim/opt/docker/docker-compose.yml`.

If the concertim components are enabled, the following containers will be installed:

* `metric_reporting_daemon` - Provides an HTTP API for receiving and processing metrics.
* `visualisation` - Provides an HTTP API for reporting racks and instances; and a web app
  for visualising the instances and their metrics.
* `proxy` - An nginx reverse proxy for the `metric_reporting_daemon` and `visualisation`
  services.
* `db` - A postgresql database.

If the cluster builder component is enabled, the following containers will be installed:

* `cluster_builder` - Provides an HTTP API for building various types of clusters on OpenStack.

If the openstack service components are enabled, the following containers will be installed:

* `api_server` - Manages OpenStack users, projects and keys for Concertim.
* `billing` - Manages interactions between the chosen billing application and other services.
* `bulk_updates` - Periodically syncs OpenStack instance state to Concertim.
* `mq_listener` - Listens to the Rabbit MQ to sync OpenStack changes to Concertim in real time.
* `metrics` - Polls OpenStack for certain metrics and reports them to Concertim.

If the killbill service was enabled, a second set of containers is installed.
They are managed by a docker compose file located at `/opt/concertim/opt/killbill/docker-compose.yml`,
and consists of the following:

* `killbill` - an opensource billing and payments platform.
* `kaui` - the Kill Bill admin user interface.
* `db` - A mariadb database.


## Docker volumes

If the concertim components are enabled, three docker volumes are created. Two
of these should be included in your sites retention policy.

* `concertim_db-data` - contains the postgresql data including the racks and instances.
  This should be included in a data retention policy.
* `concertim_rrd-data` - contains the historial metrics as rrd file.
  This should be included in a data retention policy.
* `concertim_static-content` - used to enable `proxy` to serve static assets.
  This does not need to be backed up.

If the killbill service is enabled, an additional docker volume is created.
It should be included in your sites retention policy.

* `killbill_db` - contains the mariadb data for Kill Bill.
  This should be included in a data retention policy.


## Directory structure on host machine

After the playbook has ran a number of files and directories will exist under `/opt/concertim`.
The most important are:

* `/opt/concertim/etc/` - configuration files for the Concertim services.  The
Concertim services can be configured by editing these files and restarting the
appropriate service.
* `/opt/concertim/usr/share/cluster-builder/` - the cluster type definitions used by the cluster builder service.
* `/opt/concertim/opt/docker/docker-compose.yml` - the docker compose configuration for the concertim services.
* `/opt/concertim/opt/docker/secrets` - credentials for the Concertim services.
  These need to remain here, but you should be careful to ensure that the directory and file permissions are secure.
* `/opt/concertim/opt/killbill/docker-compose.yml` - the docker compose configuration for the Kill Bill services.
* `/opt/concertim/opt/killbill/secrets` - credentials for the Kill Bill service.
  These need to remain here, but you should be careful to ensure that the directory and file permissions are secure.


Other directories include:

* `/opt/concertim/opt/ansible-playbook/` the ansible playbook that was cloned earlier in these instructions.
* `/opt/concertim/opt/visualisation-app/` the source code for Concertim Visualisation App.  It is used to build a docker image.
* `/opt/concertim/opt/metric-reporting-daemon/` the source code for Concertim Metric Reporting Daemon.  It is used to build a docker image.
* `/opt/concertim/opt/proxy/` configuration for building an nginx reverse proxy docker image.
* `/opt/concertim/opt/openstack-service/` the source code for Concertim OpenStack Service.  It is used to build a docker image.
