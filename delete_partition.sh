#!/bin/bash
set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <disk> <partition_number>"
    echo "Example: $0 /dev/sda 4"
    exit 1
fi

DEVICE="$1"
PART_NUM="$2"
TARGET_PART="${DEVICE}${PART_NUM}"

success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; }
info() { echo -e "\e[34m[INFO]\e[0m $1"; }

# Handle nvmeXnY-style naming (e.g., /dev/nvme0n1p4)
if [[ "$DEVICE" == *"nvme"* ]]; then
    TARGET_PART="${DEVICE}p${PART_NUM}"
fi

# Safety checks
if [ ! -b "$DEVICE" ]; then
    error "$DEVICE is not a valid block device."
    exit 1
fi

if [ ! -b "$TARGET_PART" ]; then
    error "Partition $TARGET_PART does not exist."
    exit 1
fi

# Unmount if mounted
if mount | grep -q "$TARGET_PART"; then
    echo "Unmounting $TARGET_PART..."
    sudo umount "$TARGET_PART"
fi

# Delete the partition
echo "Deleting partition $TARGET_PART..."
echo -e "d\n$PART_NUM\nw" | sudo fdisk "$DEVICE"

# Reload partition table
echo "Reloading partition table..."
sudo partprobe "$DEVICE"

success "Partition $TARGET_PART deleted."
lsblk
