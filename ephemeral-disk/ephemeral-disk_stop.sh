#!/bin/sh
set -e

[ ! -r /etc/default/ephemeral-disk ] && exit 1

. /etc/default/ephemeral-disk

if [ "$SWAP" -eq "1" ]; then
    swap="/dev/$VG_NAME/$LV_SWAP"
    r_swap=$(realpath "$swap")

    for device in $(swapon -s|tail -n +2|awk '{print $1}'); do
        r_device=$(realpath "$device")

        if [ "$r_device" = "$r_swap" ]; then
            echo "Desactivating swap ..."
            swapoff "/dev/$VG_NAME/$LV_SWAP"
        fi
    done
fi

if [ "$DESTROY_ON_STOP" -eq "1" ]; then
    echo "Removing data mountpoint ..."
    rmdir "$MOUNT_PATH"

    if [ "$SWAP" -eq "1" ]; then
        echo "Removing LVM swap partition ..."
        lvremove -f "$VG_NAME/$LV_SWAP"
    fi

    echo "Removing LVM data partition ..."
    lvremove -f "$VG_NAME/$LV_DATA"

    echo "Removing LVM storage ..."
    vgremove -f "$VG_NAME"
    pvremove -f "${DISK}1"

    echo "Wiping disk ..."
    wipefs -f --all "$DISK"
fi
