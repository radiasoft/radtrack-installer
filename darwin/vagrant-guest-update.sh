#!/bin/bash
set -e
host_version=$1
iso=VBoxGuestAdditions_$host_version.iso
iso_dir=$(pwd)

clean_up() {
    set +e
    trap - EXIT
    cd "$iso_dir"
    umount /mnt &> /dev/null
    rm -f "$iso"
}
trap clean_up EXIT

rpms=$(rpm -qa | grep VirtualBox)
if [[ $rpms ]]; then
    yum remove -y $rpms || true
fi

curl -s -S -L -O http://download.virtualbox.org/virtualbox/$host_version/$iso
mount -t iso9660 -o loop,rw $iso /mnt
# Sometimes this prompts for something. It should fail or default in this case.
sh /mnt/VBoxLinuxAdditions.run < /dev/null
