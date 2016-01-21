
# ephemeral-scripts

Boris HUISGEN <bhuisgen@hbis.fr>

Systemd units to prepare, use and backup your data on Amazon EC2 ephemeral disks.

## Dependencies

    # apt install make parted lvm2

## ephemeral-disk

This script prepares the ephemeral drive at each system boot by creating:
* a LVM volume group *ephemeral*
* a LVM logical volume *swap* for swap space (if enabled in configuration)
* a LVM logical volume *data* which will be mounted in */ephemeral/data*.

If the partitions are already present, nothing is done except mounting them. After mounting, the service starts all required services using data on the ephemeral storage.

The LVM volume group will have sufficient free space to allow snapshot creation and backup. The second script *ephemeral-backup* will do the job for you.

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

or at any time:

    # systemctl start ephemeral-backup.service

### FAQ

* How to restore my ephemeral disk from a previous snasphot ?

To restore a previous snapshot, stop your services:

    # systemctl stop ephemeral-units.service

Copy the snapshot archive file to restore and extract it:

    # cd /ephemeral/data
    # rm -fr .
    # tar xzf /mnt/ebs/host/data-snap01012016.tar.gz

Restart the services:

    # systemctl start ephemeral-units.service

* How to upgrade a previous installation of these scripts ?

If your ephemeral disk has been partitioned by a previous version of these scripts, you need first to make a backup of your data:

    # systemctl start ephemeral-backup.service

Then proceed to the uninstallation:

    # cd ~/ephemeral-scripts/ephemeral-backup/
    # make stop && make uninstall

    # cd ~/ephemeral-scripts/ephemeral-disk/
    # make stop && make uninstall

You can now install the latest scripts and restore your data.
