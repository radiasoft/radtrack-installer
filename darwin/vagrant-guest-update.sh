#!/bin/bash
#
# Update guest additions if host_version out of date
#
set -e
guest_version=$(sudo perl -e 'print((`VBoxControl --version` =~ /([\d\.]+)/)[0])')
if [[ $vbox_version == $guest_version ]]; then
    exit 1
fi

iso=VBoxGuestAdditions_$vbox_version.iso
start_dir=$(pwd)

clean_up() {
    set +e
    trap - EXIT
    cd "$start_dir"
    umount /mnt &> /dev/null
    rm -f "$iso"
}
trap clean_up EXIT

#TODO(robnagler) Is this robust enough?
rpms=$(rpm -qa | grep VirtualBox)
if [[ $rpms ]]; then
    yum remove -y $rpms || true
fi

curl -s -S -L -O "http://download.virtualbox.org/virtualbox/$vbox_version/$iso"
mount -t iso9660 -o loop,rw "$iso" /mnt
# Returns false even when it succeeds, if the reload fails (next),
# then the guest additions didn't get added right (or something else
# is wrong). Sometimes this prompts, but if it does, ignore it as we
# can't make this that robust. If there is no ~/RadTrack, then we will
# have a failure anyway.
sh /mnt/VBoxLinuxAdditions.run < /dev/null || true
exit 0
