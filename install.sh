#!/bin/sh

parted /dev/sda mklabel gpt
parted /dev/sda mkpart "efi" fat32 1MiB 16MiB 
parted /dev/sda mkpart "boot" ext4 16MiB 1040MiB # 1GiB для boot
parted /dev/sda mkpart "root" btrfs 1040MiB 100%
parted /dev/sda set 1 esp on

mkfs.fat -F 32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.btrfs /dev/sda3

mkdir /mnt/installfs
mount /dev/sda3 /mnt/installfs

btrfs subvolume create /mnt/installfs/@
btrfs subvolume create /mnt/installfs/@home
btrfs subvolume create /mnt/installfs/@log
btrfs subvolume create /mnt/installfs/@backups

umount /mnt/installfs -R

mount -o rw,noatime,compress=lzo,ssd,ssd_spread,discard=async,space_cache=v2,subvol=/@ [устройство]3 /mnt/installfs
mkdir /mnt/installfs/home
mount -o rw,noatime,compress=lzo,ssd,ssd_spread,discard=async,space_cache=v2,subvol=/@home [устройство]3 /mnt/installfs/home
mkdir -p /mnt/installfs/var/log
mount -o rw,noatime,compress=lzo,ssd,ssd_spread,discard=async,space_cache=v2,subvol=/@log [устройство]3 /mnt/installfs/var/log
mkdir /mnt/installfs/backups
mount -o rw,noatime,compress=lzo,ssd,ssd_spread,discard=async,space_cache=v2,subvol=/@backups [устройство]3 /mnt/installfs/var/backups

mkdir /mnt/installfs/boot
mount /dev/sda2 /mnt/installfs/boot

mkdir /mnt/installfs/boot/efi
mount /dev/sda1 /mnt/installfs/boot/efi

timedatectl set-timezone Europe/Moscow

pacman-key --init && pacman-key --populate archlinux

sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

pacman -Syy --noconfirm reflector
reflector --country Russia --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

pacstrap -K /mnt \
    base \
    base-devel \
    linux-zen \
    linux-zen-headers \
    linux-firmware \
    intel-ucode \
    networkmanager \
    btrfs-progs \
    bash-completion \
    ttf-jetbrains-mono

