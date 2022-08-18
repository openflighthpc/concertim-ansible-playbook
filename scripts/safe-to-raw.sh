#!/bin/bash

set -e
set -o pipefail
set -x

# XXX Use partitions as they are defined in a persistent_image.yaml file.
# XXX Remove hardcoding of loop back device.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR="${SCRIPT_DIR}"/..

# XXX Allow these to be set as command line arguments.
TARFILE=MIA-6-4-0-DEV.tgz
FILESYSTEM=MIA-6-4-0-DEV
DISK_SIZE=$(( 32 * 1024 )) # 32G

FSTAB_FILE="${ROOT_DIR}/templates/fstab"
FILESYSTEM_PATH="${ROOT_DIR}/filesystems/${FILESYSTEM}/system" 
IMG_FILE="${ROOT_DIR}/disk.img"
LOOP_DEV=
MOUNT_POINT=/mnt/staging
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
    if [ -d "${FILESYSTEM_PATH}" ]; then
        log "Tarfile already extracted"
    else
        log "Extracting ${TARFILE}"
        tar xzf "${TARFILE}" --numeric-owner -ps
        if [ ! -d "${FILESYSTEM_PATH}" ]; then
            echo "${FILESYSTEM_PATH} not found"
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

    sfdisk "${tmp_loop_dev}" < "${SCRIPT_DIR}"/partitions.sfdisk
    losetup -d "${tmp_loop_dev}"
}

setup_crypto() {
    log "Setting up crypto"
    setup_crypto_part "/dev/mapper/${LOOP_DEV}p2" system-rootfs  /etc/keys/rootfs.key
    setup_crypto_part "/dev/mapper/${LOOP_DEV}p3" upgrade-rootfs /etc/keys/rootfs.key
    setup_crypto_part "/dev/mapper/${LOOP_DEV}p5" swap
    setup_crypto_part "/dev/mapper/${LOOP_DEV}p6" private-data   /etc/keys/private-data.key
    setup_crypto_part "/dev/mapper/${LOOP_DEV}p7" upgrade-data   /etc/keys/upgrade-data.key
    mkdir -p "${CRYPTO_TMPDIR}"/etc/
    cp -a "${ROOT_DIR}"/templates/crypttab "${CRYPTO_TMPDIR}"/etc/
}

setup_crypto_part() {
    local src tgt key_file
    src="$1"
    tgt="$2"
    key_file="${FILESYSTEM_PATH}${3}"

    if [ -b /dev/mapper/${tgt} ]; then
        /sbin/cryptsetup -q remove ${tgt}
    fi

    # Deal with encrypted swap.
    if [ "${tgt}" == "swap" ] ; then
        /sbin/cryptsetup -q create "${tgt}" "${src}" --key-file /dev/urandom
        return 0
    fi

    # Deal with non-swap encryptions.
    if [ -f "${key_file}" ] ; then
        # The key is in the filesystem. It will be rsynced along with the rest
        # of the disk.
        :
    else
        # Create the key in CRYPTO_TMPDIR. It will be rsynced later.
        key_file="${CRYPTO_TMPDIR}${3}" 
        mkdir -p "$(dirname "${key_file}")"
        /bin/dd if=/dev/urandom of="${key_file}" bs=1 count=32
    fi

    # Check to see if luks is already on this disk and openable.
    if ! /sbin/cryptsetup isLuks "${src}" && ! /sbin/cryptsetup -q luksOpen "${src}" "${tgt}" --key-file "${key_file}" ; then
        /sbin/cryptsetup -q luksFormat --type luks1 "${src}" "${key_file}" && \
            /sbin/cryptsetup -q luksOpen "${src}" "${tgt}" --key-file "${key_file}"
    fi
}

create_loopback_devices() {
    log "Creating loopback devices"
    kpartx -av "${IMG_FILE}" 
    LOOP_DEV="$( losetup -j "${IMG_FILE}"  | cut -d: -f1 | sed 's,/dev/,,' )"
}

format_partitions() {
    log "Creating filesystems"
    mkfs -t ext3 -L _boot         -O ^metadata_csum /dev/mapper/${LOOP_DEV}p1
    mkfs -t ext4 -L _             -O ^metadata_csum /dev/mapper/system-rootfs
    mkfs -t ext4 -L _upgrade      -O ^metadata_csum /dev/mapper/upgrade-rootfs
    mkfs -t ext4 -L _data_private -O ^metadata_csum /dev/mapper/private-data
    mkfs -t ext4 -L _data_upgrade -O ^metadata_csum /dev/mapper/upgrade-data
    mkfs -t ext4 -L _data_public  -O ^metadata_csum /dev/mapper/${LOOP_DEV}p8

    mkswap -L SWAP-sda5 /dev/mapper/swap
}

mount_partitions() {
    log "Mounting partitions"
    mkdir -p "${MOUNT_POINT}"

    mount_encrypted_partition /dev/mapper/${LOOP_DEV}p2 system-rootfs / "${FILESYSTEM_PATH}"/etc/keys/rootfs.key

    mkdir -p "${MOUNT_POINT}"/{boot,upgrade,data/private,data/upgrade,data/public}
    mount /dev/mapper/${LOOP_DEV}p1 "${MOUNT_POINT}"/boot

    mount_encrypted_partition /dev/mapper/${LOOP_DEV}p3 upgrade-rootfs /upgrade      "${FILESYSTEM_PATH}"/etc/keys/rootfs.key
    mount_encrypted_partition /dev/mapper/${LOOP_DEV}p6 private-data   /data/private "${CRYPTO_TMPDIR}"/private-data.key
    mount_encrypted_partition /dev/mapper/${LOOP_DEV}p7 upgrade-data   /data/upgrade "${CRYPTO_TMPDIR}"/upgrade-data.key

    mount /dev/mapper/${LOOP_DEV}p8 "${MOUNT_POINT}"/data/public/
}

mount_encrypted_partition() {
    local src tgt key_file mntpt
    src="$1"
    tgt="$2"
    mntpt="$3"
    key_file="${4}"

    if [ ! -b /dev/mapper/"${tgt}" ] ; then
        /sbin/cryptsetup -q luksOpen "${src}" "${tgt}" --key-file "${key_file}"
    fi
    if ! mount -t auto /dev/mapper/${tgt} "${MOUNT_POINT}${mntpt}" ; then
        echo "Failed to mount ${tgt} to "${MOUNT_POINT}${mntpt}""
        exit 1
    fi
}

sync_disk() {
    log "Syncing disks"
    rsync -a --delete-after "${FILESYSTEM_PATH}/" "${MOUNT_POINT}"
    if compgen -G "${CRYPTO_TMPDIR}/etc/keys/*.key" ; then
        rsync -a "${CRYPTO_TMPDIR}/etc/keys/" "${MOUNT_POINT}"/etc/keys
    fi
    rsync -a "${CRYPTO_TMPDIR}/etc/crypttab" "${MOUNT_POINT}"/etc/
}

sync_patches() {
    log "Syncing patched files"
    rsync -a patches/ "${MOUNT_POINT}"
}

build_fstab() {
    log "Building fstab"
    rsync -a "${FSTAB_FILE}" "${MOUNT_POINT}"/etc/fstab
}

# install_bootloader() {
#     log "Installing bootloader"
#     chroot "${MOUNT_POINT}" /bin/bash <<EOF
#     echo "in chroot"
#     if [ -f /usr/sbin/safe.install_bootloader ] ; then
#         /usr/sbin/safe.install_bootloader 1 2 3
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
    rsync -a --delete-after "${SCRIPT_DIR}"/stage-2/ "${MOUNT_POINT}"/root/stage-2-scripts
}

unstage_disks() {
    log "Unstaging disks"
    umount "${MOUNT_POINT}"/data/public  || true
    umount "${MOUNT_POINT}"/data/upgrade || true
    umount "${MOUNT_POINT}"/data/private || true
    umount "${MOUNT_POINT}"/upgrade      || true
    umount "${MOUNT_POINT}"/boot         || true
    umount "${MOUNT_POINT}"              || true

    remove_encrypted_mapper system-rootfs
    remove_encrypted_mapper upgrade-rootfs
    remove_encrypted_mapper swap
    remove_encrypted_mapper private-data
    remove_encrypted_mapper upgrade-data

    kpartx -dv "${IMG_FILE}"
}

remove_encrypted_mapper() {
    local tgt
    tgt="$1"
    if [ -b /dev/mapper/${tgt} ]; then
        /sbin/cryptsetup -q remove "${tgt}"
    fi
}

prepare_disks() {
    log "Preparing disks"
    create_raw
    create_partitions
    create_loopback_devices
    setup_crypto
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
    sync_patches
    build_fstab
    # install_bootloader
    # post_deployment

    install_stage_2_scripts

    unstage_disks
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap unstage_disks EXIT
    main "$@"
fi
