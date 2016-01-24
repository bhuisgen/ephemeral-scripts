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
        echo "Removing LVM LV $VG_NAME/$LV_SWAP ..."
        lvremove -f "$VG_NAME/$LV_SWAP"
    fi

    echo "Removing LVM LV $VG_NAME/$LV_DATA ..."
    lvremove -f "$VG_NAME/$LV_DATA"

    echo "Removing LVM VG $VG_NAME ..."
    vgremove -f "$VG_NAME"

    oldIFS=$IFS
    IFS=','
    for disk in $DISKS; do
        echo "Removing LVM PV ${disk}1 ..."
        pvremove -f "${disk}1"

        echo "Wiping disk ${disk} ..."
        wipefs -f --all "$disk"
    done
    IFS=$oldIFS
fi
