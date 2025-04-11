#!/bin/bash
set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <disk> (e.g., /dev/sda or /dev/nvme0n1)"
    exit 1
fi

DEVICE="$1"

success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; }
info() { echo -e "\e[34m$1\e[0m"; }

if [ ! -b "$DEVICE" ]; then
    error "$DEVICE is not a valid block device."
    exit 1
fi

echo "Free space on $DEVICE..."
sudo parted --script -m "$DEVICE" unit GB print free # sudo parted --script -m /dev/sda unit GB print free
echo

# Detect and disable active swap partitions on this device
SWAP_PARTS=$(swapon --noheadings --show=NAME | grep -F "$DEVICE" || true)
if [ -n "$SWAP_PARTS" ]; then
    echo "$SWAP_PARTS" | xargs -n1 sudo swapoff # sudo swapoff /dev/sda99
    echo "Disabled swap on partition(s): $SWAP_PARTS"
fi

# Print fdisk instructions
echo -e "\n[INSTRUCTION] Now will run 'sudo fdisk $DEVICE'"
echo "Inside fdisk, press:"
echo "  n   → new partition"
echo "  (choose default partition number)"
echo "  (press Enter to accept default start sector)"
echo "  (press Enter to accept default end sector)"
echo "  w   → write and save changes"

read -p $'\nPress ENTER when you are ready'
sudo fdisk $DEVICE # sudo fdisk /dev/sda, then 'n', 'enter', 'enter', 'enter', 'w'

# Reload partition table
sudo partprobe "$DEVICE" # sudo partprobe /dev/sda

# Re-enable swap
if [ -n "$SWAP_PARTS" ]; then
    echo "$SWAP_PARTS" | xargs -n1 sudo swapon # sudo swapon /dev/sda99
    echo "Re-enabled swap on partition(s): $SWAP_PARTS"
fi

success "You can now format and mount the new partition"
lsblk
