
# ephemeral-scripts

Boris HUISGEN <bhuisgen@hbis.fr>

A set of shell scripts to prepare and backup Amazon EC2 ephemeral disks.

## Dependencies

    # apt install lvm2 make parted

## ephemeral-disk

This script prepares the ephemeral drive at each system boot by creating:
* a swap space on the first partition
* a LVM volume group *ephemeral* on the second partition
* a LVM logical volume *data* which will be mounted in */ephemeral/data*.

If the partitions are already created, nothing is done except mounting. But you can configure the script to destroy the ephemeral disk at each reboot/shutdown.

The LVM volume group will have free space to allow snapshot creation and backup. The second script *ephemeral-backup* will do the job for you.

After partitions creation, the script will start the services which need and use the ephemeral storage.

### Installation

    # cd ephemeral-disk/

    # cp ephemeral-disk.dist ephemeral-disk
    # vim ephemeral-disk

    # cp ephemeral-units.service.dist ephemeral-units.service
    # vim ephemeral-units.service

    # make install
    # make start

### Usage

Start the ephemeral disk services:

    # make start

Check that the data and swap partitions are created and mounted:

    # cat /proc/swaps
    # lvs
    # cd /ephemeral/data

Verify you bootorder after a system restart:

    # systemd-analyze plot > bootorder.svg

The unit *ephemeral-units.service* must be started before all your service units which need the ephemeral storage.

## ephemeral-backup

This script backups the ephemeral data by creating a LVM snapshot of the ephemeral data partition. You need to create a shell script to execute your custom commands on the LVM snapshot which will be mounted in */ephemeral/snapshot*.

### Installation

    # cd ephemeral-backup/

    # cp ephemeral-backup.dist ephemeral-backup
    # vim ephemeral-backup

    # cp backup.sh.dist backup.sh
    # vim backup.sh

    # cp ephemeral-backup-daily.timer.dist ephemeral-backup-daily.timer

    # make install

The timer *ephemeral-backup-daily.timer* will run periodically the service *ephemeral-backup.service*.

### Usage

Start the ephemeral backup service:

    # make start

To start a backup immediately:

    # make backup
