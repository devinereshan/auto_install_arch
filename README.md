```
# curl https://raw.githubusercontent.com/devinereshan/auto_install_arch/master/base_install > base_install
# chmod u+x base_install
# ./base_install
```

```
# arch-chroot /mnt
# curl https://raw.githubusercontent.com/devinereshan/auto_install_arch/master/configure > configure
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
