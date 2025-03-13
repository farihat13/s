#!/bin/bash

set -e  # Exit on error

# Ensure both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <disk> <mount_point>"
    echo "Example: $0 /dev/sdb /mnt/data"
    echo ""
    echo "Available disks:"
    lsblk -o NAME,FSTYPE,MOUNTPOINT,SIZE,TYPE
    exit 1
fi

DISK="$1"
MOUNT_POINT="$2"

# Check if the provided disk exists
if [ ! -b "$DISK" ]; then
    echo "Error: $DISK is not a valid block device."
    exit 1
fi

# Check if the disk has a filesystem
FSTYPE=$(lsblk -no FSTYPE "$DISK")

# If no filesystem is detected, format the disk as ext3
if [ -z "$FSTYPE" ]; then
    echo "Formatting $DISK as ext4..."
    sudo mkfs.ext4 -q "$DISK"
fi

# Create the mount point if it does not exist
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
fi

# Mount the disk
sudo mount "$DISK" "$MOUNT_POINT"
echo "Successfully mounted $DISK to $MOUNT_POINT"

# Change ownership of the mount point to match the home directory owner
USER_OWNER=$(stat -c "%U" "$HOME")
GROUP_OWNER=$(stat -c "%G" "$HOME")
sudo chown "$USER_OWNER":"$GROUP_OWNER" "$MOUNT_POINT"

# Create a symlink in the home directory for easy access
SYMLINK_PATH="$HOME/$(basename "$MOUNT_POINT")"
if [ -L "$SYMLINK_PATH" ]; then
    rm "$SYMLINK_PATH"
fi
ln -s "$MOUNT_POINT" "$SYMLINK_PATH"
echo "Symlink created: $SYMLINK_PATH -> $MOUNT_POINT"

exit 0
