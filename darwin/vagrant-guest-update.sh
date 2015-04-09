#!/bin/sh
version=$1
iso=VBoxGuestAdditions_$version.iso
wget http://download.virtualbox.org/virtualbox/$version/$iso
mount -t iso9660 -o loop $iso /mnt
cd /mnt
sh VBoxLinuxAdditions.run
cd
umount /mnt
rm -f $iso
