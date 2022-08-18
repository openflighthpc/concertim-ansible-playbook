#!/bin/bash

# echo 319f4d26e3c536b5dd871bb2c52e3178 > /root/rootfs
# /sbin/cryptsetup -q luksOpen /dev/sda2 system-rootfs --key-file /root/rootfs
# mkdir /mnt/staging
# mount -t auto /dev/mapper/system-rootfs /mnt/staging

MOUNT_POINT=/mnt/staging
DISK=/dev/sda
KEY_DIR="${MOUNT_POINT}/etc/keys"

mkdir -p "${MOUNT_POINT}"
mount "${DISK}"1 "${MOUNT_POINT}"/boot

/sbin/cryptsetup -q luksOpen /dev/sda3 upgrade-rootfs --key-file "${KEY_DIR}"/rootfs.key
mount -t auto /dev/mapper/upgrade-rootfs "${MOUNT_POINT}"/upgrade/

/sbin/cryptsetup -q luksOpen /dev/sda6 private-data --key-file "${KEY_DIR}"/private-data.key
mount -t auto /dev/mapper/private-data   "${MOUNT_POINT}"/data/private/

/sbin/cryptsetup -q luksOpen /dev/sda7 upgrade-data --key-file "${KEY_DIR}"/upgrade-data.key
mount -t auto /dev/mapper/upgrade-data   "${MOUNT_POINT}"/data/upgrade/

mount "${DISK}"8 "${MOUNT_POINT}"/data/public/

mkdir -p "${MOUNT_POINT}"/{dev,proc,sys}
mount -o bind /dev "${MOUNT_POINT}"/dev
mount -t proc none "${MOUNT_POINT}"/proc
mount -t sysfs none "${MOUNT_POINT}"/sys
