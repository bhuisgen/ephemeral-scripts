#!/bin/sh
set -e

[ ! -r /etc/default/ephemeral-disk ] && exit 1

. /etc/default/ephemeral-disk

LV_DISK="/dev/$VG_NAME/$LV_DATA"

if [ ! -b "$LV_DISK" ]; then
    echo "Wiping disk ..."
    wipefs -f --all "$DISK"

    echo "Partitioning disk ..."
    sh -c "(/bin/echo -e ',,8e')|/sbin/sfdisk ${DISK} --DOS --IBM -uM --quiet"
    partprobe

    echo "Preparing LVM storage ..."
    pvcreate -f "${DISK}1"
    vgcreate -f "$VG_NAME" "${DISK}1"

    if [ "$SWAP" -eq "1" ]; then
        echo "Preparing LVM swap partition ..."
        lvcreate -L "$LV_SWAP_SIZE" -n "$LV_SWAP" "$VG_NAME"
        mkswap -f "/dev/$VG_NAME/$LV_SWAP"
    fi
    echo "Preparing LVM data partition ..."
    lvcreate -l "$LV_DATA_SIZE" -n "$LV_DATA" "$VG_NAME"
    sh -c "mkfs.$MOUNT_FSTYPE -F \"/dev/$VG_NAME/$LV_DATA\""
fi

if [ "$SWAP" -eq "1" ]; then
    echo "Activating swap ..."
    swapon "/dev/$VG_NAME/$LV_SWAP"
fi

echo "Creating data mountpoint ..."
mkdir -p "$MOUNT_PATH"
