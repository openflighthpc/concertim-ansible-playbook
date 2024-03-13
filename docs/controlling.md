# Controlling the Alces Concertim Docker containers

## Starting and stopping the Concertim services

After the playbook has ran all of the Concertim services are running.

The services can be stopped by running:

```bash
docker compose -f /opt/concertim/opt/docker/docker-compose.yml stop
```

The services can be started by running:

```bash
docker compose -f /opt/concertim/opt/docker/docker-compose.yml start
```

A single service can be restarted by running the following,
where `<service>` is one of the services mentioned above,
e.g., `metric_reporting_daemon`, `visualisation`, `proxy`, `db`:

```bash
docker compose -f /opt/concertim/opt/docker/docker-compose.yml restart <service>
```

The Kill Bill service can be started, stopped or restarted by running:

```bash
docker compose -f /opt/concertim/opt/killbill/docker-compose.yml {start|stop|restart}
```


## Configuring a Concertim service

To configure the `metric_reporting_daemon` service:

1. Edit the file `/opt/concertim/etc/metric-reporting-daemon.yml`.
2. Restart the service see [Starting and stopping services](#starting-and-stopping-the-concertim-services).

To configure the `visualisation` service:

1. Log in to the visualisation web app as the `admin` user.
2. Navigate to "Cloud environment".
3. Enter the configuration details and click "Create" (or "Update").

To configure the `cluster_builder` service:

New cluster type definitions can be added by adding the definition to
`/opt/concertim/usr/share/cluster-builder/cluster-types-available`
and then creating a *relative* symlink to
`/opt/concertim/usr/share/cluster-builder/cluster-types-enabled`.

Cluster type definitions can be disabled by removing the symlink from
`/opt/concertim/usr/share/cluster-builder/cluster-types-enabled`.

Both changes will be picked up without need to restart the cluster builder
service.

To configure the `conertim openstack` service:

1. Edit the file `/opt/concertim/etc/openstack-service/config.yaml`.
2. Restart the all of the services see [Starting and stopping services](#starting-and-stopping-the-concertim-services).

Configuration of the `proxy` and `db` services is not currently supported.
