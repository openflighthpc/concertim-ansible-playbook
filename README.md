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
5. Boot the VirtualBox machine from live cd and perform final configuration.
6. Boot the VirtualBox machine from the VMDK.

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
   disk_uuid=$(VBoxManage list hdds | grep -B5 -A4 MIA-6-4-0-DEV.vmdk)
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
installing the Grub bootloader.

### Determine root partition encryption key

First the password for decrypting the root partition needs to be determined.
To do this you will need MAC address of the first network interface of the
virutal machine, e.g., `08:00:27:F0:F3:CF`.  Once you have the MAC address,
run the following to obtain the "vanilla passwords pool index".

These commands are to be ran on your laptop.

```
MAC_ADDRESS=<mac address of VM's first network interface>
printf %02d $(expr $(printf '%d' 0x`md5sum <(echo ${MAC_ADDRESS} | tr 'A-Z' 'a-z') | cut -c1-2`) % 20) ; echo
```

This will give you an index in the range `00-19`.

Once you have the "vanilla passwords pool index", the "disk password seed" can
be found by running:

```
index=<the index determined above>
cat filesystems/MIA-6-4-0-DEV/system/data/private/share/vanilla/${index}.vars
```

Once you have the "disk password seed" you can determine the "root partition
encryption key" by running:

```
seed=<disk password seed>
echo -n $( echo "${seed}" | cut -c 1-8 ) | md5sum | cut -f1 -d' '
```


### Mount root and other partitions

Once the root partition encryption key has been determined, the root partition
can be mounted inside the VM.  Once that is done, the other partitions can
then also be mounted.

These commands are to be ran on the VM.

1. Mount the root partition
   ```
   echo <root partition encryption key> > /root/rootfs.key
   /sbin/cryptsetup -q luksOpen /dev/sda2 system-rootfs --key-file /root/rootfs.key
   mount -t auto /dev/mapper/system-rootfs /mnt/staging
   ```
2. Mount the other partitions
   ```
   /mnt/staging/root/stage-2-scripts/mount-mia-disks.sh
   ```

### Run post-deploy script and install bootloader

Once the partitions have been mounted, the post-deploy script can be ran and
the bootloader installed.

These commands are to be ran on the VM.

```
chroot /mnt/staging
/usr/local/sbin/safe.postdeploy.sh
/usr/sbin/safe.install_bootloader 1 2 3
echo $?
```

The final line of output should be `0`, if it isn't investigate and fix!


## Boot machine from VMDK

1. Shut machine off.
2. Remove live CD.
2. Start machine.

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
section below.

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

1. Create a shared folder.
2. `svn co //dev.concertim.com/svn/phoenix/src/share/demo/ganglia_data_generator/branches/uranus-concertim some/shared/folder/path`
3. On mia install and run fake ganglia generator.
   ```
   cp -a /mnt/shared/folder/path /root/ganglia_data_generator
   cd /root
   chown -R root:root ganglia_data_generator
   chmod -R o+r ganglia_data_generator
   chmod o+x ganglia_data_generator

   cd /root/ganglia_data_generator/AUTOSTART
   ./Install.sh
   /etc/init.d/fake-ganglia status
   ```

## Run First time setup wizard

### Ensure Virtual box can access usb devices

```
sudo adduser $USER vboxusers
```

Log out and in again.  Perhaps even reboot the machine.

### Install virtual box guest additions

1. Edit `/etc/network/interfaces` to have eth0 dhcp. `ifdown eth0`, `ifup
   eth0`.
2. `apt-get install -y dkms build-essential linux-headers-$(uname -r)`
3. Mount Guest additions CD: `mount -t auto /dev/sr0 /mnt/sr0`.
4. Fiddle about with `/usr/src`.  `/usr/src` is a symlink to
   `/data/private/src`.  This symlink breaks relative path symlinks
   installed by `linux-headers-$(uname -r)` which breaks the installation
   of guest additions.
   ```
   rm /usr/src
   mkdir /usr/src
   cp -a /data/private/src/linux* /usr/src
   ```
5. Run guest additions installer; `/mnt/sr0/VBoxLinuxAdditions.run`.
6. Unfiddle with `/usr/src`.
   ```
   find /usr/src -type l -exec rm {} \;
   rm -rf /usr/src
   ln -s /data/private/src /usr/src
   ```
7. Unedit `/etc/network/interfaces`.
8. Reboot machine.

### Run the setup wizard

1. Find link local address of the machine: `avahi-browse -d appliance.local
   --all --terminate --resolve`.
2. Visit FTSW: `https://169.254.x.y`.
3. Plug in USB key containing personality etc..

