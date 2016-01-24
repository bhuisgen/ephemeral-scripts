#!/bin/sh
set -e

[ ! -r /etc/default/ephemeral-disk ] && exit 1

. /etc/default/ephemeral-disk

LV_DISK="/dev/$VG_NAME/$LV_DATA"

if [ ! -b "$LV_DISK" ]; then
    oldIFS=$IFS
    IFS=','
    for disk in $DISKS; do
        echo "Wiping disk $disk ..."
        wipefs -f --all $disk

        echo "Partitioning disk $disk ..."
        parted --script ${disk} mklabel gpt
        parted --script --align optimal ${disk} mkpart primary ext4 2048s 100%
        parted --script ${disk} set 1 lvm on

        echo "Creating LVM PV ${disk}1 ..."
        pvcreate -f ${disk}1
    done
    IFS=$oldIFS

    echo "Probing partitions ..."
    partprobe

    echo "Creating LVM VG $VG_NAME ..."
    oldIFS=$IFS
    IFS=','
    for disk in $DISKS; do
        disks_list="$disks_list ${disk}1"
    done
    IFS=$oldIFS
    disks_list=${disks_list## }
    vgcreate -f $VG_NAME $disks_list

    if [ "$SWAP" -eq "1" ]; then
        echo "Creating LVM LV $VG_NAME/$LV_SWAP ..."
        lvcreate --yes -L "$LV_SWAP_SIZE" -n "$LV_SWAP" "$VG_NAME"

        echo "Formating swap partition ..."
        mkswap -f "/dev/$VG_NAME/$LV_SWAP"
    fi

    echo "Creating LVM LV $VG_NAME/$LV_DATA ..."
    lvcreate --yes -l "$LV_DATA_SIZE" -n "$LV_DATA" "$VG_NAME"

    echo "Formating data partition ..."
    sh -c "mkfs.$MOUNT_FSTYPE -F \"/dev/$VG_NAME/$LV_DATA\""
fi

if [ "$SWAP" -eq "1" ]; then
    echo "Activating swap ..."
    swapon "/dev/$VG_NAME/$LV_SWAP"
fi

echo "Creating data mountpoint ..."
mkdir -p "$MOUNT_PATH"
