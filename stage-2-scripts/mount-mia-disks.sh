#!/bin/bash

MOUNT_POINT=/mnt/staging
DISK=/dev/sdb

mkdir -p "${MOUNT_POINT}"
mount "${DISK}"2 "${MOUNT_POINT}"
mount "${DISK}"1 "${MOUNT_POINT}"/boot
mount "${DISK}"3 "${MOUNT_POINT}"/upgrade/
mount "${DISK}"6 "${MOUNT_POINT}"/data/private/
mount "${DISK}"7 "${MOUNT_POINT}"/data/upgrade/
mount "${DISK}"8 "${MOUNT_POINT}"/data/public/
