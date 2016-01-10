#!/bin/bash
set -e

[ ! -r /etc/default/ephemeral-disk ] && exit 1

. /etc/default/ephemeral-disk

echo "Disabling swap ..."
swapoff "$SWAP_DISK"

if [ "$DESTROY_ON_STOP" -eq "1" ]; then
    echo "Removing data mountpoint ..."
    rmdir "$MOUNT_PATH"

    echo "Removing LVM partitions ..."
    lvremove -f "$VG_NAME/$LV_NAME"
    vgremove -f "$VG_NAME"
    pvremove -f "$VG_DISK"

    echo "Wiping disk ..."
    wipefs -f "$DISK"
fi
