# Bootstrap MIA virtual box

## Overview

1. Create RAW disk image from safe persistent image.
2. Create VirtualBox VMDK disk image from RAW disk image.
3. Create VirtualBox machine using VMDK image.
4. Boot VirtualBox machine from live cd and perform final configuration.
5. Boot VirtualBox machine from VMDK.

## Create RAW disk image

1. Download MIA-6-4-0-DEV.tgz from build.concertim.com.
2. Run `safe-to-raw.sh`.


## Create VirtualBox VMDK image

First clean up any unwanted VirtualBox VMDKs built with this process.

1. Shutdown any machine using image.
2. Remove the VMDK from the machine.
3. Find the UUID of the VMDK with `VBoxManage list hdds | grep -B5 -A4 MIA-6-4-0-DEV.vmdk`.
4. Delete the VMDK with `VBoxManage closemedium disk <DISK_UUID> --delete`.

With that done, create the new VMDK.

1. `sudo VBoxManage convertfromraw disk.img MIA-6-4-0-DEV.vmdk --format VMDK`
2. `sudo chown $(id -un):$(id -gn) MIA-6-4-0-DEV.vmdk`


## Create a VirtualBox machine using the VMDK image.

1. Networks
2. Optical drives
3. Disks

## Boot machine from Live CD.

1. Fix networks
2. Mount disks
3. chroot; bind mount /dev, mount /proc and /sys; run
   `/usr/local/sbin/safe.postdeploy.sh`; run
   `/usr/sbin/safe.install_bootloader 1 2 3`.


## Boot machine from VMDK

1. Shut machine off.
2. Remove live CD.
2. Start machine.
