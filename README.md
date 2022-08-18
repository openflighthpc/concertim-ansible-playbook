# Bootstrapping Concertim MIA as VirtualBox virtual machine

This repo contains instructions and scripts to build Concertim MIA as a
VirtualBox machine.  The instructions are to build version 6.4.0 aka
`uranus-concertim`.

## Overview

The rough process is as follows:

1. Download the `MIA-6-4-0-DEV.tgz` safe-persistent image from
   build.concertim.com.
2. Create a RAW disk image from that safe-persistent image.
3. Create a VMDK disk image from that RAW disk image.
4. Create a suitable VirtualBox machine.
5. Boot the VirtualBox machine from live cd and perform post-installation configuration.
6. Boot the VirtualBox machine from the VMDK.
7. Install guest additions.
8. Fix SSL/TLS issues.
9. Install the fake metric generator.

The machine is then ready for the first-time setup wizard to be ran, or to be
exported as an `OVF`/`OVA` for distribution.

## Download the safe-persistent image

The `MIA-6-4-0-DEV.tgz` safe-persistent image needs to be obtained.  It can be
downloaded from `build.concertim.com`.

1. Ensure you have a copy of the Concertim SSH configuration and SSH key.
2. Download the safe-persistent image to this repo:
   ```
   scp  -i /path/to/concertim/id_dsa -F /path/to/concertim/config  build:/data/build/tarfiles/MIA-6-4-0-DEV.tgz .
   ```

The `scp` command will fail if `build.concertim.com` is not running.  In which
case, start the "Build" EC2 instance in the `us-east-1` region of the Alces
Flight Concertim AWS account.  You will need to obtain appropriate AWS
credentials to do so.

NOTE: If you start the `build.concertim.com` machine, make sure to stop it
once you have downloaded the image.


## Create RAW disk image from safe-persistent image

Once the safe-persistent image has been downloaded, a RAW disk image can be
created from it by running `safe-to-raw.sh` on your laptop.

This script emulates much of the work done by safe-persistent deploy.

1. Run `sudo safe-to-raw.sh`.


## Create VMDK image from RAW disk image

First clean up any unwanted VMDK images that have previously been built
with this process.

1. Shutdown any machine using the VMDK disk image.
2. Remove the VMDK from any such machines.
3. Delete the VMDK with
   ```
   disk_uuid=$(VBoxManage list hdds | grep -B5 -A4 MIA-6-4-0-DEV.vmdk | grep '^UUID:' | awk '{print $2}')
   if [ "${disk_uuid}" == "" ] ; then
     echo "Unable to find disk UUID"
   else
     VBoxManage closemedium disk --delete "${disk_uuid}"
   fi
   ```

With that done, create the new VMDK.

1. ```
   sudo VBoxManage convertfromraw disk.img MIA-6-4-0-DEV.vmdk --format VMDK
   sudo chown $(id -un):$(id -gn) MIA-6-4-0-DEV.vmdk
   ```


## Create a VirtualBox machine using the VMDK image.

XXX Finish detailing what this should be.

1. Networks 2
2. Optical drive
3. Disk attached to VMDK above.
4. 4 processors.
5. 8G of RAM.

## Boot machine from Live CD.

Before the VMDK is ready to be used to boot the machine, some additional
post-deploy configuration is required.  This includes configuring and
installing the Grub bootloader.  The process to do this is roughly:

1. determine the root partition's encryption key.
2. boot the machine from a Live CD.
3. mount the partitions including the encrypted partitions.
4. run the safe post install script and the safe install bootloader script.

### Determine root partition encryption key

When first created the root partition is encrypted with a "default encryption
key".  Once the `safe.postdeploy.sh` script has been ran the "default
encryption key" is removed and a "vanilla encryption key" is added in its
place.  Later, when the "first-time setup wizard" is ran the "vanilla
encryption key" is removed and a "config pack encryption key" added in its
place.

In general, determining the root partiion encryption key is complicated by the
above.  However, if these instructions are followed as laid out, the root
partition encryption key can be found by running the following on your laptop:

```
cat filesystems/MIA-6-4-0-DEV/system/etc/keys/rootfs.key
```

Details on how to obtain the "vanilla encryption key" and "config pack
encryption key" are given in docs/encryption-keys.md


### Boot the machine from a Live CD

1. Download the Ubuntu 16.04 Desktop i386 Live CD.  (Other versions may work).
2. Attach it to the VM's optical drive.
3. Edit the VM's boot order, so that it boots from the optical drive.


### Mount root and other partitions

Once the root partition encryption key has been determined, the root partition
can be mounted inside the VM.  Once that is done we can run a script to mount
the other partitions.

These commands are to be ran as `root` on the VM.

1. Mount the root partition
   ```
   echo <root partition encryption key> > /root/rootfs.key
   /sbin/cryptsetup -q luksOpen /dev/sda2 system-rootfs --key-file /root/rootfs.key
   mkdir /mnt/staging
   mount -t auto /dev/mapper/system-rootfs /mnt/staging
   ```
2. Mount the other partitions
   ```
   /mnt/staging/root/stage-2-scripts/mount-mia-disks.sh
   ```

### Run post-deploy script and install bootloader

Once the partitions have been mounted, the post-deploy script can be ran and
the bootloader installed.

These commands are to be ran as `root` on the VM.

```
/mnt/staging/root/stage-2-scripts/prepare-chroot.sh
chroot /mnt/staging
/usr/local/sbin/safe.postdeploy.sh
/usr/sbin/safe.install_bootloader 1 2 3
echo $?
```

The final line of output should be `0`, if it isn't investigate and fix!  It's
important to check the exit code of `safe.install_bootloader` as it can fail
silently.


## Boot machine from VMDK

The machine should now be booted from the VMDK image.  To do so.

1. Shut machine off.
2. Remove live CD (or change boot order).
3. Start machine.

Once booted the VirutalBox guest additions can be installed.

## Login to the VM

Login to the VM as root, the password can be found be following the
instructions given in docs/vanilla-passwords.md.  You could login either on
the VirtualBox console or via SSH.


Using SSH requires the file `ssh/config` to be edited with the VMs link local
address.  You can then SSH into the appliance with 

```
ssh -F ssh/config command
```

You may need to adjust your laptop's routes to access the VM via SSH.

## Install VirtualBox guest additions

Installation of the VirtualBox guest additions is complicated by a number of
issues.  Use the process below to install the guest additions.

1. Ensure the VM can access the outside world.  Edit `/etc/network/interfaces`
   and replace the line `iface eth0 inet manual` with `iface eth0 inet dhcp`.
   ```
   ifdown eth0
   ifup eth0
   ```

2. Install build dependencies
   ```
   apt-get install -y dkms build-essential linux-headers-$(uname -r)
   ```

3. Fiddle about with `/usr/src`.  `/usr/src` is a symlink to
   `/data/private/src`.  This symlink breaks relative path symlinks
   installed by `linux-headers-$(uname -r)` which breaks the installation
   of guest additions.
   ```
   rm /usr/src
   mkdir /usr/src
   cp -a /data/private/src/linux* /usr/src
   ```

4. Add VirtualBox guest additions to the VMs optical drive and mount the Guest
   additions CD:
   ```
   mkdir /mnt/sr0
   mount -t auto /dev/sr0 /mnt/sr0
   ```

5. Run guest additions installer
   ```
   /mnt/sr0/VBoxLinuxAdditions.run
   ```

6. Unfiddle with `/usr/src`.
   ```
   find /usr/src -type l -exec rm {} \;
   rm -rf /usr/src
   ln -s /data/private/src /usr/src
   ```

7. Undo the change made to `/etc/network/interfaces`.

## Fix TLSv1.0 issue

The version of OpenSSL installed on MIA-6.4.0 supports only TLSv1.0.  Most
(all?) modern browsers refuse to use this protocol preventing the appliance
from being accessed.  To fix this OpenSSL needs upgrading and Apache2
recompiling to use the new version.

WARNING: There is a backport of `openssl-1.0.1c` available for squeeze.  That
version provides `TLSv1.2` which we need but is unfortunately vulnerable to
the hearbleed bug.  It is unlcear to me whether the backport contains a fix
for this security issue.  I've decided that use of `openssl-1.0.1c` is
acceptable for a demo appliance, though we will obviously want to address this
issue for a production appliance.

### Compile and install OpenSSL 1.0.1c

Get a checkout of https://github.com/mezentsev/OpenSSL-Backport on to the
appliance at `/root/OpenSSL-Backport`.

Using `curl`, `wget` or `git` to download the backport may fail due to
OpenSSL being too old.  I experienced such issues with some of my attempts to
upgrade OpenSSL.  They may or may not have been with Github.  YMMV.

If the backport cannot be downloaded directly to the appliance, it could be
downloaded to your laptop and shared with the appliance via a shared folder.
In order to use shared folders the VirtualBox Guest Additiona need to be
installed.  There are some issues with doing that; see the Guest Additions
section above.

Once the backport has been downloaded to the appliance it can be built and
installed.  To do so you will need to have a GPG key with which to sign the
package.  You can use the `Concurrent Thinking Appliance Patches` key for
this.  It's 8-digit key id can be determined by running

```
gpg --list-keys 'Concurrent Thinking Appliance Patches'
```

You will also need the passphrase for this key.  That can be found on
`dev.concertim.com` in the file `/usr/local/setup/gpg/patches.key`.

You can now compile and install the OpenSSL backport:

```
cd /root/OpenSSL-Backport
# Remove the .git directory otherwise dpkg-buildpackage gets upset.
rm -rf .git
cd openssl-1.0.1c
dpkg-buildpackage -k<Patches Key ID>
cd ../
dpkg -i *.deb
```


### Re-compile and install Apache2

Apache2's `mod_ssl` is dynamically linked to use `libssl.so.0.9.8`.  This can
be determined by running `ldd /usr/lib/apache2/modules/mod_ssl.so`.  To get
`mod_ssl` to use the newly installed OpenSSL it needs to be recompiled.

1. Add the following lines to `/etc/apt/sources.list`
   ```
   deb-src http://archive.debian.org/debian-archive/debian/ squeeze main contrib non-free
   deb-src http://archive.debian.org/debian-archive/debian/ squeeze-lts main contrib non-free
   ```
2. Run the following to compile and install.
   ```
   apt-get install dpatch libaprutil1-dev libapr1-dev libpcre3-dev libcap-dev autoconf
   mkdir /root/apache2
   cd /root/apache2
   apt-get update
   apt-get source apache2
   cd apache2-2.2.16
   dpkg-buildpackage -k<Patches Key ID>
   cd ..
   dpkg -i *.deb
   ```
3. Check that `mod_ssl` is now dynamically linked to `libssl.so.1.0.0`.
   ```
   ldd /usr/lib/apache2/modules/mod_ssl.so
   ```
   The output should include `libssl.so.1.0.0` and `libcrypto.so.1.0.0`.

## Add fake metric generator

The demo appliance needs a fake metric generator installing.  There is a
suitable program available at the Subversion repo URL
https://dev.concertim.com/svn/phoenix/src/share/demo/ganglia_data_generator/branches/uranus-concertim.

Either check this out directly on the appliance or check it out on your laptop
and use shared folders to copy it to `/root/ganglia_data_generator`.  Either
way, you will need suitable authentication and for the `dev.concertim.com` EC2
instance to be running.

```
svn co https://dev.concertim.com/svn/phoenix/src/share/demo/ganglia_data_generator/branches/uranus-concertim /root/ganglia_data_generator
cd /root
chown -R root:root ganglia_data_generator
chmod -R o+r ganglia_data_generator
chmod o+x ganglia_data_generator

cd /root/ganglia_data_generator/AUTOSTART
./Install.sh
```

The fake ganglia data generator will now be automatically started each time
the appliance boots.  The status of the fake ganglia data generator can be
determined with the following.  However, it is not instructive to do so until
the appliance has had the first-time setup wizard ran.

```
/etc/init.d/fake-ganglia status
```
