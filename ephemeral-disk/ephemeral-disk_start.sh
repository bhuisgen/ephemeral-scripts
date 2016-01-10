#!/bin/bash
set -e

[ ! -r /etc/default/ephemeral-disk ] && exit 1

. /etc/default/ephemeral-disk

LV_DISK="/dev/mapper/$VG_NAME/$LV_NAME"

if [ ! -b "$LV_DISK" ]; then
    echo "Wiping disk ..."
    dd if=/dev/zero of="$DISK" bs=512 count=1
    wipefs -f "$DISK"

    echo "Partitioning disk ..."
    sh -c "(/bin/echo -e ',${SWAP_SIZE},S\n,,8e')|/sbin/sfdisk ${DISK} --DOS --IBM -uM --quiet"
    partprobe

    echo "Preparing swap ..."
    mkswap -f "$SWAP_DISK"

    echo "Preparing data storage ..."
    pvcreate "$VG_DISK"
    vgcreate "$VG_NAME" "$VG_DISK"
    lvcreate -l "$LV_SIZE" -n "$LV_NAME" "$VG_NAME"
    sh -c "mkfs.$MOUNT_FSTYPE -F $LV_DISK"
fi

echo "Activating swap ..."
swapon "$SWAP_DISK"

echo "Creating data mountpoint ..."
mkdir -p "$MOUNT_PATH"
