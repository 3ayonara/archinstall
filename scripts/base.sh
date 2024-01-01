#!/bin/bash

# Get the list of block devices
disk_devices=$(lsblk -d -n -o name)
echo "Here are your hard drives:"
echo "$disk_devices"
echo -e "\n"
read -p "Enter the disk you want to install: " disk

# Set timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohchwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo "arch" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.0.1 arch.localdomain arch" >> /etc/hosts

# Add user
useradd -m -g users -G wheel -s /bin/bash aaron
echo "aaron ALL=(ALL) ALL" >> /etc/sudoers.d//aaron

# Set password
read -rsp "Enter aaron password: " userpassword
echo -e "\n"
echo "aaron:$userpassword" | chpasswd
echo -e "\n"
read -rsp "Enter root password: " rootpassword
echo -e "\n"
echo "root:$rootpassword" | chpasswd

pacman -S efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools base-devel linux-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups pipewire pipewire-alsa pipewire-pulse pipewire-jack openssh rsync acpi acpi_call virt-manager qemu qemu-arch-extra edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font

# pacman -S --noconfirm xf86-video-amdgpu
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable fstrim.timer
systemctl enable libvirtd
systemctl enable firewalld
systemctl enable acpid

# Systemd Boot
bootctl --path=/boot install
echo "timeout 3" >> /boot/loader/loader.conf
echo "default arch" >> /boot/loader/loader.conf

disk_uuid=$(blkid -s UUID -o value "/dev/${disk}p2")
mapper_uuid=$(blkid -s UUID -o value "/dev/mapper/root")

cat <<EOF > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options cryptdevice=UUID=$disk_uuid:root root=UUID=$mapper_uuid rootflags=subvol=@ rw
EOF

cp /boot/loader/entries/arch.conf /boot/loader/entries/arch-fallback.conf
sed -i 's/initrd \/initramfs-linux.img/initrd \/initramfs-linux-fallback.img/' /boot/loader/entries/arch-fallback.conf

clear

echo "👇 Please execute the following command!"
echo -e "\n"
echo "exit"
echo "umount -R /mnt"
echo -e "\n"
echo "Done! You can reboot now."