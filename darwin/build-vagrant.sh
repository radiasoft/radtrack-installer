#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Build the Fedora 21 VM and create package.box.
#
set -e
version=$(perl -e 'print((`vboxmanage --version` =~ /([\d\.]+)/)[0])')

if [[ ! $version ]]; then
    echo 'virtual box not installed' 1>&2
    exit 1
fi

# Unlikely to connect to network
build_container_net=10.10.10
. ./build-setup.sh

vagrant destroy
rm -f package.box
rm -f Vagrantfile
set -e
# Must be different than install-user.sh; Must match iptables
guest_ip=$build_container_net.2
cat > Vagrantfile <<EOF
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "hansode/fedora-21-server-x86_64"
  config.ssh.forward_x11 = true
  config.vm.network "private_network", ip: "$guest_ip"
end
EOF
vagrant up
#TODO(robnagler) Run on target host, not here, because guest should
#  match host. Indeed, it may be a downgrade.
vagrant ssh -c "sudo bash /vagrant/vagrant-guest-update.sh $version"
vagrant reload
vagrant ssh -c "sudo bash /vagrant/build-linux.sh"
vagrant halt
vagrant package --output package.box
vagrant box add radiasoft/radtrack package.box
echo 'See README.md to upload'
