## Disable reflector service
```
systemctl stop reflector.service
```

## Verify that it is in UEFI mode
```
ls /sys/firmware/efi/efivars
```

## Connect to a network
```
iwctl
device list 
station wlan0 scan
station wlan0 get-networks
station wlan0 connect wifi-name
exit
```

## Updating the system clock
```
timedatectl set-ntp true
timedatectl status 
```

## Partitioning and formatting (using the Btrfs file system)

### Format drive
```
wipefs --all /dev/nvme0n1
```
### Partitioning
```
cfdisk /dev/nvme0n1
```
<p align="center">
  <img src="../assets/Partitioning-drives.png" width="700"/>
</p>

### Create encryption
```
cryptsetup --cipher aes-xts-plain64 --hash sha512 --use-random --verify-passphrase luksFormat /dev/nvme0n1p2
```
### Open partition
```
cryptsetup luksOpen /dev/nvme0n1p2 root
```
### Format paritions
```
mkfs.fat -F32 /dev/nvme0n1p1
mkfs.btrfs /dev/mapper/root
```
### Create sub-volumes
```
mount /dev/mapper/root /mnt
cd /mnt
btrfs subvolume create @
btrfs subvolume create @home
cd
umount /mnt
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@ /dev/mapper/root /mnt
mkdir /mnt/{boot,home}
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@home /dev/mapper/root /mnt/home/
mount /dev/nvme0n1p1 /mnt/boot
```
## Install base system
```
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs
pacstrap /mnt networkmanager openssh vim sudo zsh zsh-completions git wget
```
## Generate fstab
```
genfstab -U /mnt >> /mnt/etc/fstab
```
## Change root
```
arch-chroot /mnt
```
# Modify mkinitcpio
```
sed -i 's/^MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
sed -i 's/\(^HOOKS=.*\)filesystems\(.*$\)/\1encrypt filesystems\2/' /etc/mkinitcpio.conf
mkinitcpio -p linux
```
# Set timezone
```
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohchwclock --systohc
```
# Locale-gen
```
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
```
# Set hostname & Host
```
echo "arch" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.0.1 arch.localdomain arch" >> /etc/hosts
```
# Add user
```
useradd -m -g users -G wheel -s /bin/bash aaron
echo "aaron ALL=(ALL) ALL" >> /etc/sudoers.d//aaron
```
# Enable default services
```
sudo systemctl enable NetworkManager
sudo systemctl enable sshd
```
# Setup boot loader (Systemd Boot)
```
bootctl --path=/boot install

# /boot/loader/loader.conf
timeout 3
default arch

# /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options cryptdevice=UUID=<UUID of /dev/nvme0n1p2>:root root=UUID=<UUID of /dev/mapper/root> rootflags=subvol=@ rw video=2560x1440

# get patition UUID
blkid /dev/nvme0n1p2
blkid /dev/mapper/root

# create fallback
cp /boot/loader/entries/arch.conf /boot/loader/entries/arch-fallback.conf

# /boot/loader/entries/arch-fallback.conf
initrd /initramfs-linux-fallback.img
```
## Unmount partition
```
exit
umount -R /mnt
```