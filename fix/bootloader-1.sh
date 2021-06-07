#!/bin/bash
sudo mount /dev/sdc5 /mnt
sudo mount /dev/sdc1 /mnt/boot/efi
for i in /dev /dev/pts /proc /sys /run; do sudo mount -B $i /mnt$i; done
sudo chroot /mnt
