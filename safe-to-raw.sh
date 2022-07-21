#!/bin/bash

set -e
set -o pipefail
set -x

# WARNING: this is totally untested at the moment.
#
# XXX Create sfdisk from $PERSISTENT_IMAGE_PATH
# XXX Remove hardcoding of partition layout.
# XXX Remove hardcoding of loop back device.
# XXX Add support for encryption.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# XXX Allow these to be set as command line arguments.
TARFILE=MIA-6-4-0-DEV.tgz
PERSISTENT_IMAGE=MIA-6-4-0-DEV-VM
FILESYSTEM=MIA-6-4-0-DEV
DISK_SIZE=$(( 32 * 1024 )) # 32G

FSTAB_FILE="${SCRIPT_DIR}/fstab"
FILESYSTEM_PATH="filesystems/${FILESYSTEM}/system" 
IMG_FILE=disk.img
LOOP_DEV=
MOUNT_POINT=/mnt/staging
PERSISTENT_IMAGE_PATH="persistent/${PERSISTENT_IMAGE}/persistent_image.yaml"
CRYPTO_TMPDIR=$(mktemp -d)

log() {
    echo "=== $@ ==="
}

sanity_check() {
    if [ $(id -u) -ne 0 ] ; then
        echo "Script must be ran as root" >&2
        exit 1
    fi

    if [ ! -f "${TARFILE}" ]; then
        echo "Unable to find ${TARFILE}.  Download from build.concertim.com" >&2
        exit 1
    fi
}

extract_tar_file() {
    if [ -d "${FILESYSTEM_PATH}" -a -f "${PERSISTENT_IMAGE_PATH}" ]; then
        log "Tarfile already extracted"
    else
        log "Extracting ${TARFILE}"
        tar xzf "${TARFILE}" --numeric-owner -ps
        if [ ! -d "${FILESYSTEM_PATH}" ]; then
            echo "${FILESYSTEM_PATH} not found"
            exit 1
        fi
        if [ ! -f "${PERSISTENT_IMAGE_PATH}" ]; then
            echo "${PERSISTENT_IMAGE_PATH} not found"
            exit 1
        fi
    fi
}

create_raw() {
    if [ -f "${IMG_FILE}" ] ; then
        log "Using existing ${IMG_FILE} size ${DISK_SIZE}"
    else
        log "Creating ${IMG_FILE} size ${DISK_SIZE}"
        dd if=/dev/zero of="${IMG_FILE}" bs=1024k seek="${DISK_SIZE}" count=0
        sync
    fi
}

create_partitions() {
    log "Configuring partitions"
    local tmp_loop_dev

    parted "${IMG_FILE}" mklabel msdos
    losetup -f "${IMG_FILE}" 

    tmp_loop_dev="$( losetup -j "${IMG_FILE}"  | cut -d: -f1 )"

    # XXX Generate partitions.sfdisk from ${PERSISTENT_IMAGE_PATH}
    sfdisk "${tmp_loop_dev}" < partitions.sfdisk
    losetup -d "${tmp_loop_dev}"
}

create_loopback_devices() {
    log "Creating loopback devices"
    kpartx -av "${IMG_FILE}" 
    LOOP_DEV="$( losetup -j "${IMG_FILE}"  | cut -d: -f1 | sed 's,/dev/,,' )"
}

format_partitions() {
    log "Creating filesystems"
    # XXX Determine filesystem type from ${PERSISTENT_IMAGE_PATH}
    # XXX Determine partition numbers from ${PERSISTENT_IMAGE_PATH}
    mke2fs -t ext3 /dev/mapper/${LOOP_DEV}p1
    mke2fs -t ext4 /dev/mapper/${LOOP_DEV}p2
    mke2fs -t ext4 /dev/mapper/${LOOP_DEV}p3
    mke2fs -t ext4 /dev/mapper/${LOOP_DEV}p6
    mke2fs -t ext4 /dev/mapper/${LOOP_DEV}p7
    mke2fs -t ext4 /dev/mapper/${LOOP_DEV}p8
    mkswap /dev/mapper/${LOOP_DEV}p5
}

mount_partitions() {
    # XXX Don't assume LOOP_DEV is the same as above.
    # XXX Determine partition numbers and mount points from ${PERSISTENT_IMAGE_PATH}
    log "Mounting partitions"
    mkdir -p "${MOUNT_POINT}"
    mount /dev/mapper/${LOOP_DEV}p2 "${MOUNT_POINT}"
    mkdir -p "${MOUNT_POINT}"/{boot,upgrade,data/private,data/upgrade,data/public}
    mount /dev/mapper/${LOOP_DEV}p1 "${MOUNT_POINT}"/boot

    mount /dev/mapper/${LOOP_DEV}p3 "${MOUNT_POINT}"/upgrade/
    mount /dev/mapper/${LOOP_DEV}p6 "${MOUNT_POINT}"/data/private/
    mount /dev/mapper/${LOOP_DEV}p7 "${MOUNT_POINT}"/data/upgrade/
    mount /dev/mapper/${LOOP_DEV}p8 "${MOUNT_POINT}"/data/public/
}

sync_disk() {
    log "Syncing disks"
    rsync -a --delete-after "${FILESYSTEM_PATH}/" "${MOUNT_POINT}"
}

build_fstab() {
    log "Building fstab"
    # XXX Remove hardcoding of fstab file content.
    rsync -a --delete-after "${FSTAB_FILE}" "${MOUNT_POINT}"/etc/fstab
}

# install_bootloader() {
#     log "Installing bootloader"
#     # XXX Remove hardcoding of kernel, initrd and bootloader.
#     local kernel_file initrd_file bootloader
#     kernel_file=vmlinuz-2.6.32-5-amd64
#     initrd_file=initrd.img-2.6.32-5-amd64
#     bootloader=grub
#     chroot "${MOUNT_POINT}" /bin/bash <<EOF
#     echo "in chroot"
#     if [ -f /usr/sbin/safe.install_bootloader ] ; then
#         /usr/sbin/safe.install_bootloader "${kernel_file}" "${initrd_file}" "${bootloader}"
#     fi
# EOF
# }

# post_deployment() {
#     log "Fixing bootloader"
#     chroot "${MOUNT_POINT}" /bin/bash <<EOF
#     echo "in chroot"
#     if [ -f /usr/local/sbin/safe.postdeploy.sh ] ; then
#         /usr/local/sbin/safe.postdeploy.sh
#     fi
# EOF
# }

install_stage_2_scripts() {
    log "Intalling stage 2 scripts"
    rsync -a --delete-after stage-2-scripts /root/stage-2-scripts
}

unstage_disks() {
    log "Unstaging disks"
    # XXX Determine mount points from ${PERSISTENT_IMAGE_PATH}
    umount "${MOUNT_POINT}"/data/public 
    umount "${MOUNT_POINT}"/data/upgrade 
    umount "${MOUNT_POINT}"/data/private
    umount "${MOUNT_POINT}"/upgrade 
    umount "${MOUNT_POINT}"/boot 
    umount "${MOUNT_POINT}"

    kpartx -dv "${IMG_FILE}"
}

prepare_disks() {
    log "Preparing disks"
    create_raw
    create_partitions
    create_loopback_devices
    format_partitions
}

stage_disks() {
    log "Staging disks"
    create_loopback_devices
    mount_partitions
}

main() {
    sanity_check
    extract_tar_file
    prepare_disks
    stage_disks
    sync_disk
    build_fstab
    # install_bootloader
    # post_deployment

    install_stage_2_scripts

    unstage_disks
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
