# /mn   /bin/bash

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
