# Developing the Concertim ansible playbook

When developing the Concertim ansible playbook, you may want to avoid running
it on your laptop.  Similarly, when testing the playbook you may want a fresh
environment on which to test it.

You could achieve both of these by using an OpenStack instance.

Alternatively, you can use a Vagrant machine defined in the
[Vagrantfile](/contrib/dev/vagrant/Vagrantfile).

To automate rebuilding the vagrant machine and running the playbook from scratch:

```bash
cd contrib/dev/vagrant
BUILD_ENV=prod ./scripts/rebuild-box.sh dev1
```

To run the playbook manually. First bring up the box.

```bash
cd contrib/dev/vagrant
vagrant up --no-provision BOX_NAME
vagrant provision --provision-with swap BOX_NAME
vagrant provision --provision-with install_ansible BOX_NAME
vagrant provision --provision-with install_docker BOX_NAME
```

Then SSH into it

```bash
vagrant ssh BOX_NAME
```

Then run the playbook:

```bash
/vagrant/scripts/run-prod-playbook.sh
```
