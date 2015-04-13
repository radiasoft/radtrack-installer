#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Build the Fedora 21 VM and create package.box.
#
version=$(perl -e 'print((`vboxmanage --version` =~ /([\d\.]+)/)[0])')

if [[ -z $version ]]; then
    echo 'virtual box not installed' 1>&2
    exit 1
fi

vagrant destroy
rm -f package.box
rm -f Vagrantfile
set -e
vagrant init hansode/fedora-21-server-x86_64
vagrant up
vagrant ssh -c "sudo bash /vagrant/vagrant-guest-update.sh $version"
vagrant reload
vagrant ssh -c 'sudo bash /vagrant/install-vagrant.sh'
vagrant halt
vagrant package --output package.box
vagrant box add radiasoft/radtrack package.box
echo 'See README.md to upload'
