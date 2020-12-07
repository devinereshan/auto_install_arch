```
# curl https://raw.githubusercontent.com/devinereshan/auto_install_arch/master/base_install > base_install
# # edit base_install script as needed (change partitioning scheme, etc...)
# chmod u+x base_install
# ./base_install
```

```
# arch-chroot /mnt
# curl https://raw.githubusercontent.com/devinereshan/auto_install_arch/master/configure > configure
# # edit configure script as needed (uncomment relevant ucode updates, etc...)
# chmod u+x configure
# ./configure
```

```
# exit
# umount /mnt/boot
# umount /mnt
# cryptsetup close cryptroot
# reboot
# ufw enable
# systemctl enable NetworkManager
# systemctl start NetworkManager
```
