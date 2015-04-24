#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Build the Fedora 21 VM and create package.box.
#
set -e
version=$(perl -e 'print((`vboxmanage --version` =~ /([\d\.]+)/)[0])')

# This code is shared, but how?

if [[ ! $version ]]; then
    echo 'virtual box not installed' 1>&2
    exit 1
fi

# Standard network for us so it always should be vboxnet0
build_container_net=10.10.10
. ./build-setup.sh

box_name=radiasoft/radtrack
vagrant destroy -f &> /dev/null || true
vagrant remove "$box_name" &> /dev/null || true
rm -rf Vagrantfile .vagrant

set -e
# Must be different than install-user.sh (so can run two VMs simultaneously)
# Shouldn't collide with existing uses (1-60) either.
guest_ip=$build_container_net.234
cat > Vagrantfile <<EOF
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "hansode/fedora-21-server-x86_64"
  config.vm.network "private_network", ip: "$guest_ip"
end
EOF
vagrant up

shopt -s nullglob

##########TODO: Don't need to do this
# Avoid copying *.box and other unnecessary files
tar cf - *.{list,pl,py,sh,so} | vagrant ssh -c "sudo bash -c 'yum install -q -y tar; mkdir /cfg; cd /cfg; tar xf -'"

#######TODO Only need to build the app, which installs RPMs possibly
vagrant ssh -c "sudo bash /cfg/build-linux.sh"
vagrant halt
vagrant package --output package.box
vagrant box add "$box_name" package.box
echo 'See README.md to upload'
