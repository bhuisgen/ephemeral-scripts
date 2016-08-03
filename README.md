# ephemeral-scripts

Boris HUISGEN <bhuisgen@hbis.fr>

Systemd units to prepare, use and backup Amazon EC2 ephemeral disks.

## ephemeral-disk

This service prepares the ephemeral disks of an Amazon EC2 instance. It will
create at each system boot a swap partition - if enabled in configuration - and
a data partition which will be mounted in the directory */ephemeral/data*. If
the partitions are already existing, nothing is done except mounting them. After
mounting, the service starts all required service dependencies like Docker or
your favorite SQL server. RAID software is also supported in case of several
ephemeral disks to optimize IO performance.

LVM is used like this:
* a volume group *ephemeral* for all disks
* a logical volume *swap* for the swap partition
* a logical volume *data* for the data partition

The volume group will have sufficient free space to allow snapshot creation and
backup with the second script *ephemeral-backup*.

### Installation

You need to install these dependencies:

    # apt install make parted lvm2

If you want to use software RAID, add this one:

    # apt install mdadm

> Before configuring the service, you need to remove your ephemeral disks from
the  */etc/fstab* file.

    # cd ephemeral-disk/

    # cp ephemeral-disk.dist ephemeral-disk
    # vim ephemeral-disk

Edit the needed options.

    # cp ephemeral-units.service.dist ephemeral-units.service
    # vim ephemeral-units.service

    # make install

> Please check install output and fix all errors found on your system before
enabling services.

### Usage

Start the ephemeral disk services:

    # make enable
    # make start

Check that swap and data partitions are created and mounted:

    # cat /proc/swaps
    # free -m
    # lvs
    # cd /ephemeral/data

To be sure verify your bootorder after a system restart:

    # systemd-analyze plot > bootorder.svg

The unit *ephemeral-units.service* must be started before all units using the
ephemeral storage.

## ephemeral-backup

This service backups the ephemeral data by creating a LVM snapshot of the
ephemeral data partition. You need to create a shell script to execute your
custom commands on the LVM snapshot which will be mounted in
*/ephemeral/snapshot*.

### Installation

    # cd ephemeral-backup/

    # cp ephemeral-backup.dist ephemeral-backup
    # vim ephemeral-backup

    # cp backup.dist backup
    # vim backup

    # cp ephemeral-backup-daily.timer.dist ephemeral-backup-daily.timer

    # make install

The timer *ephemeral-backup-daily.timer* will run periodically the service
*ephemeral-backup.service* to start a backup.

### Usage

Start the ephemeral backup timer:

    # make enable
    # make start

To start a backup immediately:

    # make backup

or at any time:

    # systemctl start ephemeral-backup.service

### FAQ

**How to restore my ephemeral disk from a previous snasphot ?**

To restore a previous snapshot, stop your services:

    # systemctl stop ephemeral-units.service

Copy the snapshot archive file to restore and extract it:

    # cd /ephemeral/data
    # rm -fr .
    # tar xzf /mnt/ebs/host/data-snap01012016.tar.gz

Restart the services:

    # systemctl start ephemeral-units.service

**How to upgrade a previous installation of these scripts ?**

If your ephemeral disk has been partitioned by a previous version of these
scripts, you need first to make a backup of your data:

    # systemctl start ephemeral-backup.service

Then proceed to the uninstallation:

    # cd ~/ephemeral-scripts/ephemeral-backup/
    # make stop && make uninstall

    # cd ~/ephemeral-scripts/ephemeral-disk/
    # make stop && make uninstall

You can now install the latest scripts and restore your data.
