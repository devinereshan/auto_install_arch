#!/usr/bin/env bash

# $1 = string to refer to user whose password is being entered
# $2 = variable to store the new password in
function getPassword() {
    local user=$1
    local -n var=$2
    stty -echo
    printf "Enter $user password: "
    read pass1
    printf "\nRe-enter $user password: "
    read pass2
    printf "\n"
    stty echo

    if [ "$pass1" != "$pass2" ]
    then
        printf "Passwords do not match!\n"
        return 1
    fi

    if [ "$pass1" = "" ]
    then
        printf "Empty password not allowed\n"
        return 1
    fi

    var="$pass1"
    return 0
}

printf "Enter hostname: "
read hostname

printf "Enter username: "
read username

status=1
while [ $status -ne 0 ]
do
    getPassword "user" user_pass
    status=$?
done

status=1
while [ $status -ne 0 ]
do
    getPassword "root" root_pass
    status=$?
done


timedatectl set-ntp true

# partition the disk
cat <<EOF | fdisk /dev/sda
o
n
p


+512M
n
p



w
EOF
partprobe

# Ensure necessary modules are loaded
modprobe dm-crypt
modprobe dm-mod

# Create encrypted partition
cryptsetup -y -v luksFormat -s 512 -h sha512 /dev/sda2
cryptsetup open /dev/sda2 cryptroot

# make filesystems
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/mapper/cryptroot

# Mount the partitions
mount /dev/mapper/cryptroot /mnt

mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Install os
pacstrap /mnt base linux linux-firmware vim man-db man-pages texinfo

# create fstab
genfstab -U /imnt >> /mnt/etc/fstab

arch-chroot /mnt

# Make swapfile
dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

printf "\n/swapfile none swap defaults 0 0\n" >> /etc/fstab

# Set timezone
ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime

# Generate locale
sed -i -e 's/#de_DE.U/de_DE.U/; s/#de_DE /de_DE /; s/#en_CA/en_CA/; s/#en_US/en_US/' /etc/locale.gen
locale-gen

printf "LANG=en_US.UTF-8" >> /etc/locale.conf

# hostname
printf "${hostname}" >> /etc/hostname
printf "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t${hostname}.localdomain\t${hostname}" >> /etc/hosts

# Set root password
printf "root:${root_pass}\n" | chpasswd

# Install some more packages
pacman --noconfirm -S grub networkmanager network-manager-applet linux-headers base-devel dosfstools mtools os-prober git ufw zsh

# uncomment depending on hardware:
#pacman -S amd-ucode
#pacman -S intel-ucode

# Configure grub for encryption and SSD TRIM
# just assume TRIM support for now. Check before running script
root_uuid=$(lsblk -f | grep sda2 | gawk '{print $4}')

sed -i "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${root_uuid}:cryptroot:allow-discards root=\/dev\/mapper\/cryptroot\"/" /etc/default/grub

# Configure mkinitcpio

sed -i "s/^HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard keymap fsck)/" /etc/mkinitcpio.conf

mkinitcpio -p linux

# Install grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# update grub config for microcode updates on fallback image. Uncomment line that applies:
sed -i "s/initrd\t\/initramfs-linux-fallback.img/initrd\t\/intel-ucode.img \/initramfs-linux-fallback.img/" /boot/grub/grub.cfg
sed -i "s/initrd\t\/initramfs-linux-fallback.img/initrd\t\/amd-ucode.img \/initramfs-linux-fallback.img/" /boot/grub/grub.cfg

# Create user
useradd -m -G wheel -s /usr/bin/zsh $username
printf "${username}:${user_pass}\n" | chpasswd

# Edit sudoers
sed -i "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers
printf "\n%%wheel ALL=(ALL) NOPASSWD: /usr/bin/loadkeys\n" >> /etc/sudoers

printf "\nDone.\n"

