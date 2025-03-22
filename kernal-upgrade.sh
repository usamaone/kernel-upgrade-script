#!/bin/bash

set -e  # Exit on error

# Print script author in green
echo -e "\e[32m=================================\e[0m"
echo -e "\e[32m Muhammad Usama \e[0m"
echo -e "\e[32m=================================\e[0m"

echo "==============================="
echo " Kernel Full Cleanup & Reinstall"
echo "==============================="

echo -e "\nIdentifying the currently running kernel..."
CURRENT_KERNEL=$(uname -r)
echo "Running kernel: $CURRENT_KERNEL"

echo -e "\nFinding installed kernels..."
INSTALLED_KERNELS=$(rpm -qa | grep '^kernel-core' | awk -F 'kernel-core-' '{print $2}')

# Remove all installed kernels
for KERNEL in $INSTALLED_KERNELS; do
    echo "Removing kernel: $KERNEL"
    dnf remove -y kernel-core-$KERNEL kernel-modules-$KERNEL kernel-devel-$KERNEL || true
done

# Clean up all files in /boot except the EFI, GRUB, and loader directories
echo -e "\nCleaning up all kernel-related files in /boot..."
find /boot -maxdepth 1 -type f -exec rm -f {} \;

echo -e "\nEnsuring EFI and GRUB directories remain untouched..."
ls -l /boot  # Show contents to confirm

# Install the latest kernel
echo -e "\nInstalling the latest kernel..."
dnf install -y kernel kernel-core kernel-modules kernel-devel

# Get the latest installed kernel version
LATEST_KERNEL=$(rpm -qa | grep '^kernel-core' | awk -F 'kernel-core-' '{print $2}' | sort -V | tail -n 1)
echo "Latest installed kernel: $LATEST_KERNEL"

# Regenerate initramfs
echo -e "\nRegenerating initramfs for the latest kernel..."
dracut -f /boot/initramfs-$LATEST_KERNEL.img $LATEST_KERNEL

# Update GRUB to boot the latest kernel by default
echo -e "\nUpdating GRUB configuration..."
grub2-mkconfig -o /boot/grub2/grub.cfg

# Set latest kernel as the default boot entry
echo -e "\nSetting latest kernel as the default boot entry..."
grub2-set-default 0

# Show which kernel will be used on next reboot
NEXT_BOOT_KERNEL=$(grubby --default-kernel)
echo -e "\n================================="
echo " Installed Kernel: $LATEST_KERNEL"
echo " Next Boot Kernel: $(basename $NEXT_BOOT_KERNEL)"
echo -e "\e[32m=================================\e[0m"
echo "Cleanup and update complete. Please reboot to apply changes."
