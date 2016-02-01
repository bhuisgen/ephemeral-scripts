#!/bin/bash

[ ! -r /etc/default/ephemeral-backup ] && exit 1

. /etc/default/ephemeral-backup

[ ! -r "$BACKUP_SCRIPT" ] && exit 2

. "$BACKUP_SCRIPT"

LOCK_FILE="/tmp/$(basename "$BACKUP_SCRIPT").lock"
ERROR_FILE="/tmp/$(basename "$BACKUP_SCRIPT").err"

[ -e "$LOCK_FILE" ] && echo "Lock file exists, aborting" && exit 3
touch "$LOCK_FILE"

function_exists() {
    declare -F "$1" > /dev/null 2>&1
}

exit_error() {
    [ ! -z "$1" ] && msg="$1" || msg="Unknown error"

    echo "$msg" > "$ERROR_FILE"
    function_exists hook_error && hook_error "$msg"

    rm -f "$LOCK_FILE"

    exit 4
}

exit_success() {
    function_exists hook_success && hook_success

    rm -f "$ERROR_FILE"
    rm -f "$LOCK_FILE"

    exit 0
}

trap 'exit_error "Backup interrupted"' SIGHUP SIGINT SIGTERM

echo "Initializing ..."
function_exists get_mount_path && MOUNT_PATH=$(get_mount_path "$MOUNT_PATH")
function_exists get_snapshot_name && LV_SNAPSHOT_NAME=$(get_snapshot_name "$LV_SNAPSHOT_NAME")
function_exists get_snapshot_size && LV_SNAPSHOT_SIZE=$(get_snapshot_size "$LV_SNAPSHOT_SIZE")
function_exists hook_init && (hook_init || exit_error "Function hook_init() failed")

echo "Checking ..."
LV_DISK="/dev/$VG_NAME/$LV_NAME"
[ ! -b "$LV_DISK" ] && exit_error "Logical volume doesn't exist, aborting"
LV_SNAPSHOT_DISK="/dev/$VG_NAME/$LV_SNAPSHOT_NAME"
[ -b "$LV_SNAPSHOT_DISK" ] && exit_error "Snapshot already exists, aborting"
function_exists hook_check && (hook_check || exit_error "Function hook_check() failed")

echo "Creating snapshot ..."
function_exists hook_before_create_snapshot && (hook_before_create_snapshot "$LV_SNAPSHOT_NAME" "$LV_SNAPSHOT_DISK" "$LV_DISK" || exit_error "Function hook_before_create_snapshot() failed")
lvcreate -s -L "$LV_SNAPSHOT_SIZE" -n "$LV_SNAPSHOT_NAME" "$VG_NAME/$LV_NAME" || exit_error "Failed to create snapshot"
function_exists hook_after_create_snapshot && (hook_after_create_snapshot "$LV_SNAPSHOT_NAME" "$LV_SNAPSHOT_DISK" "$LV_DISK" || exit_error "Function hook_after_create_snapshot() failed")

echo "Mounting snapshot ..."
mkdir -p "$MOUNT_PATH"
mount "$LV_SNAPSHOT_DISK" "$MOUNT_PATH" || exit_error "Failed to mount snapshot"

echo "Starting backup ..."
function_exists hook_backup && (hook_backup "$MOUNT_PATH" "$LV_SNAPSHOT_NAME" "$LV_SNAPSHOT_DISK" "$LV_DISK" || exit_error "Function hook_backup() failed")

echo "Unmounting snapshot..."
umount "$MOUNT_PATH" || exit_error "Failed to umount snapshot"
rmdir "$MOUNT_PATH"

echo "Removing snapshot ..."
lvremove -f "$VG_NAME/$LV_SNAPSHOT_NAME" || exit_error "Failed to remove snapshot"

exit_success
