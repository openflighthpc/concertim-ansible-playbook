# Upgrading an Alces Concertim installation

## Quick start

1. Create the `RELEASE_TAG` and `GH_TOKEN` variables, with the Concertim
   release tag and you GitHub token respectively.
2. Update the ansible playbook repository to the new version.
3. Stop and remove all of the concertim containers and images.
4. Remove the concertim `concertim_static-content` volume.
5. Re-run the playbook.

```bash
RELEASE_TAG="..."
GH_TOKEN="..."
```

```bash
cd /opt/concertim/opt/ansible-playbook/
git fetch -p
git checkout --quiet ${RELEASE_TAG}

concertim_images=$(docker compose -f /opt/concertim/opt/docker/docker-compose.yml images --quiet)
docker compose -f /opt/concertim/opt/docker/docker-compose.yml down
docker image rm ${concertim_images}

docker volume rm concertim_static-content

cd /opt/concertim/opt/ansible-playbook/ansible
ansible-playbook \
  --inventory inventory.ini \
  --extra-vars "gh_token=$GH_TOKEN" \
  --extra-vars @etc/globals.yaml \
  playbook.yml
```

## Upgrade in more detail

1. Create the `RELEASE_TAG` and `GH_TOKEN` variables.

   `RELEASE_TAG` should contain the desired release tag to update to, e.g,. `v1.2.0`.
   `GH_TOKEN` should contain your GitHub token. This will need to be able to
   clone the Concertim repositories from the `alces-flight` organisation.

   ```bash
   RELEASE_TAG="..."
   GH_TOKEN="..."
   ```

2. Update the ansible playbook repository ot the new version.

   ```bash
   cd /opt/concertim/opt/ansible-playbook/
   git fetch 
   git checkout --quiet ${RELEASE_TAG}
   ```

3. Stop and remove all of the concertim containers and images.

   Currently there is [an
   issue](https://github.com/alces-flight/concertim-ansible-playbook/issues/85)
   in the concertim container versioning that may result in the docker images
   not being correctly rebuilt.  To work around that issue stop and remove all
   of the containers and then remove all of the concertim images.

   ```bash
   concertim_images=$(docker compose -f /opt/concertim/opt/docker/docker-compose.yml images --quiet)
   docker compose -f /opt/concertim/opt/docker/docker-compose.yml down
   docker image rm ${concertim_images}
   ```

4. Remove the `concertim_static-content` docker volume.

   Currently there is [an
   issue](https://github.com/alces-flight/concertim-ansible-playbook/issues/87)
   where changes in Concertim assets might not be picked up during an upgrade.
   To work around that we remove the static content volume.

   ```bash
   docker volume rm concertim_static-content
   ```

5. Re-run the playbook.  It will rebuild the images; install updated
   configuration files; re-create the containers and restart the services.

   ```bash
   cd /opt/concertim/opt/ansible-playbook/ansible
   ansible-playbook \
     --inventory inventory.ini \
     --extra-vars "gh_token=$GH_TOKEN" \
     --extra-vars @etc/globals.yaml \
     playbook.yml
   ```
