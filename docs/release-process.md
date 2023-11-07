# Process for creating a new release of Concertim Ansible Playbook

The `main` branch of `concertim-ansible-playbook` is configured to build the
latest development versions of the Concertim components, i.e., Concertim Metric
Reporting Daemon, Concertim Visualisation App, Concertim Openstack Service and
Concertim Cluster Builder.  Tagged versions of `concertim-ansible-playbook`,
e.g., `v0.2.2`, are created to build specific tagged versions of the Concertim
components.  This document describes the process to create a tagged version.

## Create tagged releases of each component

Each Concertim component should be released and tagged according to its own
process.  For the code examples below let's assume that the following tagged
versions have been created:

* Metric reporting daemon: v0.2.2
* Visualisation app: v0.2.3
* Cluster builder: v0.1.3
* Openstack service: v0.2.0

## Create release branch and update build scripts and documentation

Create a release branch for the new version of `concertim-ansible-playbook`,
e.g., if we're about to tag `v0.2.2`, create a branch `release/v0.2.2`.

Update `<component>.source.commitish` values for each concertim component in
`production/group_vars/all`.  Using the example versions above the commit would
look like this:

```diff
diff --git a/production/group_vars/all b/production/group_vars/all
index d867a5f..f38c6cb 100644
--- a/production/group_vars/all
+++ b/production/group_vars/all
@@ -69,17 +69,17 @@ enable_openstack_service: no
 metric_reporting_daemon:
   install_dir: "{{ct_installation_dir}}/metric-reporting-daemon"
   source:
     repo: "https://{{gh_token}}@github.com/alces-flight/concertim-metric-reporting-daemon"
-    commitish: main
+    commitish: v0.2.2
   docker_image:
     name: concertim-metric-reporting-daemon
 
 visualisation_app:
   install_dir: "{{ct_installation_dir}}/visualisation-app"
   source:
     repo: "https://{{gh_token}}@github.com/alces-flight/concertim-ct-visualisation-app"
-    commitish: main
+    commitish: v0.2.3
   docker_image:
     name: concertim-visualisation-app
 
 proxy:
@@ -90,17 +90,17 @@ proxy:
 cluster_builder:
   install_dir: "{{ct_installation_dir}}/cluster-builder"
   source:
     repo: "https://{{gh_token}}@github.com/alces-flight/concertim-cluster-builder"
-    commitish: main
+    commitish: v0.1.3
   docker_image:
     name: concertim-cluster-builder
 
 openstack_service:
   install_dir: "{{ct_installation_dir}}/openstack-service"
   source:
     repo: "https://{{gh_token}}@github.com/alces-flight/concertim-openstack-service"
-    commitish: develop
+    commitish: v0.2.0
   docker_images:
     - name: concertim-api-server
       dockerfile: ./Dockerfiles/Dockerfile.api_server
     - name: concertim-bulk-updates
```

Update the installation instructions to reference the new tag.  The code
snippets and prose should use the new tag instead of the branch `main`.  The
instructions to use a released version should be changed to instructions to use
an alternate release or the development version.  Using the example versions
above, the commit would look like this:


```diff
diff --git a/production/README.md b/production/README.md
index a22be5c..cf5aebd 100644
--- a/production/README.md
+++ b/production/README.md
@@ -10,9 +10,9 @@ of the Alces Concertim services as a set of Docker containers.
   `docker-compose-plugin` installed.
 * Make a GitHub token available in the `GH_TOKEN` environment variable.
 * Gain a root shell on the target machine.
-* Clone the github repo to `/opt/concertim/ansible-playbook` and checkout the `main` branch.
+* Clone the github repo to `/opt/concertim/ansible-playbook` and checkout the `v0.2.2` branch.
   ```bash
-  RELEASE_TAG="main"
+  RELEASE_TAG="v0.2.2"
   mkdir -p /opt/concertim/opt
   cd /opt/concertim/opt
   git clone -n --depth=1 --filter=tree:0 --no-single-branch \
@@ -87,12 +87,13 @@ snippets.
 Clone this github repo to the machine that will run the ansible playbook.
 The repo is a private repo,
 so you will need to have a github token available in the `GH_TOKEN` environment variable.
-The following snippet will clone the `main` branch of the repo to `/opt/concertim/ansible-playbook`,
+The following snippet will clone the `v0.2.2` branch of the repo to `/opt/concertim/ansible-playbook`,
 it is also careful to avoid downloading more data than is needed.
-If you wish to install a released version, you should follow the instructions for that release.
+If you wish to install an alternate release, you should follow the instructions for that release.
+If you wish to install the development version, you should follow the instructions for the `main` branch.
 
 ```bash
-RELEASE_TAG="main"
+RELEASE_TAG="v0.2.2"
 mkdir -p /opt/concertim/opt
 cd /opt/concertim/opt
 git clone -n --depth=1 --filter=tree:0 --no-single-branch \
```

Update the main README to reference the new tag.  The README should inform the
user that they are viewing a tagged version.  It should also instruct the user
on how to find the instructions for an alternative release and the development
release.  Using the example versions above, the commit would look like this:

```diff
diff --git a/README.md b/README.md
index 767b628..0f18b4d 100644
--- a/README.md
+++ b/README.md
@@ -7,13 +7,16 @@ development of Concertim.
 
 ## Deploying Alces Concertim
 
-You are viewing the development version of Alces Concertim Ansible Playbook.
+You are viewing release `v0.2.2` of Alces Concertim Ansible Playbook.
 To deploy this version of Alces Concertim follow [these
 instructions](production/README.md).
 
-To deploy a released version of Alces Concertim select the tag for that
+To deploy an alternate release of Alces Concertim select the tag for that
 release and follow the deployment instructions there.
 
+To deploy the development version of Alces Concertim select the `main` branch
+and follow the deployment instructions there.
+
 ## Developing
 
 For details on how to develop and test the ansible deployment playbook see
```


## Merge release branch

After the release has been tested.  Merge the release branch to `main` and
create the appropriate tag.


## Move `main` back to building dev versions

Once the release branch has been merged and the tag has been created, `main`
should be updated to point to the development versions.  This is done by
undoing the commits above.  Using the example versions above, the commit would
look like this:


```diff
diff --git a/README.md b/README.md
index 0f18b4d..767b628 100644
--- a/README.md
+++ b/README.md
@@ -7,16 +7,13 @@ development of Concertim.
 
 ## Deploying Alces Concertim
 
-You are viewing release `v0.2.2` of Alces Concertim Ansible Playbook.
+You are viewing the development version of Alces Concertim Ansible Playbook.
 To deploy this version of Alces Concertim follow [these
 instructions](production/README.md).
 
-To deploy an alternate release of Alces Concertim select the tag for that
+To deploy a released version of Alces Concertim select the tag for that
 release and follow the deployment instructions there.
 
-To deploy the development version of Alces Concertim select the `main` branch
-and follow the deployment instructions there.
-
 ## Developing
 
 For details on how to develop and test the ansible deployment playbook see
diff --git a/production/README.md b/production/README.md
index cf5aebd..a22be5c 100644
--- a/production/README.md
+++ b/production/README.md
@@ -10,9 +10,9 @@ of the Alces Concertim services as a set of Docker containers.
   `docker-compose-plugin` installed.
 * Make a GitHub token available in the `GH_TOKEN` environment variable.
 * Gain a root shell on the target machine.
-* Clone the github repo to `/opt/concertim/ansible-playbook` and checkout the `v0.2.2` branch.
+* Clone the github repo to `/opt/concertim/ansible-playbook` and checkout the `main` branch.
   ```bash
-  RELEASE_TAG="v0.2.2"
+  RELEASE_TAG="main"
   mkdir -p /opt/concertim/opt
   cd /opt/concertim/opt
   git clone -n --depth=1 --filter=tree:0 --no-single-branch \
@@ -87,13 +87,12 @@ snippets.
 Clone this github repo to the machine that will run the ansible playbook.
 The repo is a private repo,
 so you will need to have a github token available in the `GH_TOKEN` environment variable.
-The following snippet will clone the `v0.2.2` branch of the repo to `/opt/concertim/ansible-playbook`,
+The following snippet will clone the `main` branch of the repo to `/opt/concertim/ansible-playbook`,
 it is also careful to avoid downloading more data than is needed.
-If you wish to install an alternate release, you should follow the instructions for that release.
-If you wish to install the development version, you should follow the instructions for the `main` branch.
+If you wish to install a released version, you should follow the instructions for that release.
 
 ```bash
-RELEASE_TAG="v0.2.2"
+RELEASE_TAG="main"
 mkdir -p /opt/concertim/opt
 cd /opt/concertim/opt
 git clone -n --depth=1 --filter=tree:0 --no-single-branch \
diff --git a/production/group_vars/all b/production/group_vars/all
index f38c6cb..d867a5f 100644
--- a/production/group_vars/all
+++ b/production/group_vars/all
@@ -70,7 +70,7 @@ metric_reporting_daemon:
   install_dir: "{{ct_installation_dir}}/metric-reporting-daemon"
   source:
     repo: "https://{{gh_token}}@github.com/alces-flight/concertim-metric-reporting-daemon"
-    commitish: v0.2.2
+    commitish: main
   docker_image:
     name: concertim-metric-reporting-daemon
 
@@ -78,7 +78,7 @@ visualisation_app:
   install_dir: "{{ct_installation_dir}}/visualisation-app"
   source:
     repo: "https://{{gh_token}}@github.com/alces-flight/concertim-ct-visualisation-app"
-    commitish: v0.2.3
+    commitish: main
   docker_image:
     name: concertim-visualisation-app
 
@@ -91,7 +91,7 @@ cluster_builder:
   install_dir: "{{ct_installation_dir}}/cluster-builder"
   source:
     repo: "https://{{gh_token}}@github.com/alces-flight/concertim-cluster-builder"
-    commitish: v0.1.3
+    commitish: main
   docker_image:
     name: concertim-cluster-builder
 
@@ -99,7 +99,7 @@ openstack_service:
   install_dir: "{{ct_installation_dir}}/openstack-service"
   source:
     repo: "https://{{gh_token}}@github.com/alces-flight/concertim-openstack-service"
-    commitish: v0.2.0
+    commitish: develop
   docker_images:
     - name: concertim-api-server
       dockerfile: ./Dockerfiles/Dockerfile.api_server
```
