# Concertim Ansible Playbook

Concertim Ansible Playbook deploys Alces Concertim services and infrastructure
components in Docker containers.

## Getting Started

You are viewing release `v1.0.0` of Alces Concertim Ansible Playbook.
To deploy this version of Alces Concertim follow [these
instructions](ansible/README.md).

To deploy an alternate release of Alces Concertim select the tag for that
release and follow the deployment instructions there.

To deploy the development version of Alces Concertim select the `main` branch
and follow the deployment instructions there.

### Concertim services

Concertim Ansible Playbook deploys containers for the following Concertim projects:

* [Concertim Visualisation App](https://github.com/alces-flight/concertim-ct-visualisation-app)
* [Concertim Metric Reporting Daemon](https://github.com/alces-flight/concertim-metric-reporting-daemon)
* [Concertim Cluster Builder](https://github.com/alces-flight/concertim-cluster-builder)
* [Concertim Openstack Service](https://github.com/alces-flight/concertim-openstack-service)

### Infrastructure components

Concertim Ansible Playbook deploys containers for the following infrastructure components:

* [Kill Bill](https://killbill.io/) an open source billing and payments platform.
* [MariaDB](https://mariadb.com/) for MySQL database.
* [Nginx](https://nginx.org/) a HTTP and reverse proxy server.
* [Postgresql](https://www.postgresql.org/) an open source object-relational database system.

## Directories

* `ansible` - Contains an Ansible playbook to deploy Concertim services and
infrastructure components in Docker containers.
* `contrib` - Contains a Vagrant development environment for developing the playbook in the `ansible` directory.  Also contains
an alternate Ansible playbook that can be used to create a development
environment for the Concertim Components.
* `docs` - Contains documentation

## Developing

For details on how to develop and test the ansible deployment playbook see
[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

If you are looking for details on how to develop the Concertim services
themselves see the [contrib/dev/README.md](contrib/dev/README.md).
