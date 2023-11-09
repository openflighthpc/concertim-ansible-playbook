# Developing the Concertim ansible playbook

When developing the Concertim ansible playbook, you may want to avoid running
it on your laptop.  Similarly, when testing the playbook you may want a fresh
environment on which to test it.

You could achieve both of these by using an OpenStack instance.
Alternatively, you can use a Vagrant machine defined in the
[Vagrantfile](/contrib/dev/vagrant/Vagrantfile).

## Gather GitHub credentials

You will need GitHub credentials to clone the Concertim repositories.
The credentials will need to be able to clone the Concertim repositories from
the `alces-flight` organisation.
Obtaining these credentials is left as an exercise for the reader.

Your GitHub credentials will need to be exported in the `GH_TOKEN` environment
variable.

## Run the playbook

To automate rebuilding the vagrant machine and running the playbook from scratch:

```sh
cd contrib/dev/vagrant
export GH_TOKEN=<your github credentials>
BUILD_ENV=prod ./scripts/rebuild-box.sh dev1
```

To run the playbook manually. First bring up the box.

```sh
cd contrib/dev/vagrant
BUILD_ENV=prod vagrant up --no-provision dev1
vagrant provision --provision-with swap dev1
vagrant provision --provision-with install_ansible dev1
vagrant provision --provision-with install_docker dev1
```

Then SSH into it

```sh
vagrant ssh dev1
```

Then run the playbook:

```sh
export GH_TOKEN=<your github credentials>
/vagrant/scripts/run-prod-playbook.sh
```

After the playbook has completed, the Concertim services will be running as docker containers.
See [ansible/README.md](/ansible/README.md) for details on how start, stop and configure them.
