#!/bin/bash
set -e

# Configuration
DEVICE=${1:-/dev/sdb}
MOUNT_POINT="/apps"

# Check root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root"
  exit 1
fi

# Check if device exists
if [ ! -b "$DEVICE" ]; then
  echo "Error: Device $DEVICE not found"
  exit 1
fi

# Partition the disk
echo "Partitioning $DEVICE..."
parted "$DEVICE" --script mklabel gpt
parted "$DEVICE" --script mkpart primary ext4 0% 100%

# Format as ext4 with 0% reserved space
echo "Formatting partition..."
mkfs.ext4 -F -m 0 "${DEVICE}1"

# Create mount point
echo "Creating mount point..."
mkdir -p "$MOUNT_POINT"

# Mount partition
echo "Mounting partition..."
mount "${DEVICE}1" "$MOUNT_POINT"

# Set ownership
echo "Setting ownership..."
chown "$USER:$USER" "$MOUNT_POINT"

# Add to fstab
echo "Configuring persistent mount..."
UUID=$(blkid -o value -s UUID "${DEVICE}1")
echo "UUID=$UUID $MOUNT_POINT ext4 defaults,uid=$USER,gid=$USER 0 2" | tee -a /etc/fstab

echo "Operation completed successfully"
