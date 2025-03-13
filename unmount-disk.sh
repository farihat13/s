#!/bin/bash

set -ex

# Ensure both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <disk> <mount_point>"
    echo "Example: $0 /dev/sdb /mnt/data"
    exit 1
fi

DISK="$1"
MOUNT_POINT="$2"

# Check if the disk is mounted
if mountpoint -q "$MOUNT_POINT"; then
    # Unmount the disk
    sudo umount "$MOUNT_POINT"
    echo "Unmounted $DISK from $MOUNT_POINT."
else
    echo "Error: $MOUNT_POINT is not currently mounted."
fi

# Remove the symlink in home directory if it exists
SYMLINK_PATH="$HOME/$(basename "$MOUNT_POINT")"
if [ -L "$SYMLINK_PATH" ]; then
    rm "$SYMLINK_PATH"
    echo "Removed symlink: $SYMLINK_PATH"
fi

# Optionally remove the empty mount point
if [ -d "$MOUNT_POINT" ] && [ -z "$(ls -A "$MOUNT_POINT")" ]; then
    sudo rmdir "$MOUNT_POINT"
    echo "Removed empty mount point: $MOUNT_POINT"
fi

exit 0
