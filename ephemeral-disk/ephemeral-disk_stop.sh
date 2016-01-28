#!/bin/sh
set -e

[ ! -r /etc/default/ephemeral-disk ] && exit 1

. /etc/default/ephemeral-disk

disks_list=""
partitions_list=""
oldIFS=$IFS
IFS=','
for disk in $DISKS; do
    disks_list="$disks_list $disk"
    partitions_list="$partitions_list ${disk}1"
done
IFS=$oldIFS
disks_list=${disks_list## }
partitions_list=${partitions_list## }

if [ "$SWAP" -eq "1" ]; then
    swap="/dev/$VG_NAME/$LV_SWAP"

    if [ -b "$swap" ]; then
        r_swap=$(realpath -q "$swap")

        for device in $(swapon -s|tail -n +2|awk '{print $1}'); do
            r_device=$(realpath "$device")
            if [ "$r_device" = "$r_swap" ]; then
                echo "Desactivating swap ..."
                swapoff "/dev/$VG_NAME/$LV_SWAP"

                break
            fi
        done
    fi
fi

if [ "$DESTROY_ON_STOP" -eq "1" ]; then
    if [ "$SWAP" -eq "1" ]; then
        echo "Removing LVM LV $VG_NAME/$LV_SWAP ..."
        lvremove -f "$VG_NAME/$LV_SWAP"
    fi

    echo "Removing LVM LV $VG_NAME/$LV_DATA ..."
    lvremove -f "$VG_NAME/$LV_DATA"

    echo "Removing LVM VG $VG_NAME ..."
    vgremove -f "$VG_NAME"

    if [ "$MD" -eq "1" ]; then
        echo "Removing LVM PV $MD_DEVICE ..."
        pvremove -f "$MD_DEVICE"

        echo "Stopping RAID device $MD_DEVICE ..."
        mdadm --stop "$MD_DEVICE"

        echo "Removing RAID device $MD_DEVICE ..."
        #mdadm --remove "$MD_DEVICE"

        echo "Wiping RAID partitions $partitions_list ..."
        mdadm --zero-superblock $partitions_list

        echo "Wiping disks $disks_list ..."
        wipefs -faq $disks_list
    else
        echo "Removing LVM PV(s) $disks_list ..."
        pvremove -f $disks_list

        echo "Wiping disk(s) $disks_list ..."
        wipefs -faq $disks_list
    fi
fi
