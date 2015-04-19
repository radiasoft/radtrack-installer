#!/bin/bash
set -e
host_version=$1
iso=VBoxGuestAdditions_$host_version.iso
trap "rm -f '$iso'" EXIT
wget http://download.virtualbox.org/virtualbox/$host_version/$iso
mount -t iso9660 -o loop $iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
