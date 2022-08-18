#!/bin/bash

MOUNT_POINT=/mnt/staging

mkdir -p "${MOUNT_POINT}"/{dev,proc,sys}
mount -o bind /dev "${MOUNT_POINT}"/dev
mount -t proc none "${MOUNT_POINT}"/proc
mount -t sysfs none "${MOUNT_POINT}"/sys
