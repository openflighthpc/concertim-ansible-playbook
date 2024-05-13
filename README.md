# Concertim Ansible Playbook

Concertim Ansible Playbook deploys Alces Concertim services and infrastructure
components in Docker containers.

## Getting Started

You are viewing the development version of Alces Concertim Ansible Playbook.
To deploy this version of Alces Concertim follow [these
instructions](docs/installation.md).

To deploy a released version of Alces Concertim select the tag for that
release and follow the deployment instructions there.

### Concertim services

Concertim Ansible Playbook deploys containers for the following Concertim projects:

* [Concertim Visualisation App](https://github.com/openflighthpc/concertim-ct-visualisation-app)
* [Concertim Metric Reporting Daemon](https://github.com/openflighthpc/concertim-metric-reporting-daemon)
* [Concertim Cluster Builder](https://github.com/openflighthpc/concertim-cluster-builder)
* [Concertim Openstack Service](https://github.com/openflighthpc/concertim-openstack-service)

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

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2024-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Concertim Ansible Playbook is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
