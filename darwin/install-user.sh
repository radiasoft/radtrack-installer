#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Step 3: Running as $install_user setup Vagrant and run patches
#
d=$(dirname "${BASH_SOURCE[0]}")
cd "$d"
unset d

. ./env.sh

# Separate directory
vm_dir=~/'Library/Application Support/org.radtrack/vagrant'

# Destroy old vagrant
if [[ ! $install_keep && ( -d $vm_dir || $(type -p vagrant) ) ]]; then
    install_msg 'Removing existing RadTrack virtual machine...'
    install_get_file remove-existing-vm.pl
    install_log perl remove-existing-vm.pl
    install_log vagrant box list
fi
install_msg 'Installing RadTrack virtual machine...'

install_log install_mkdir "$vm_dir"
cd "$vm_dir"

guest_ip=10.13.48.2
guest_name=$install_host_id
cat > Vagrantfile <<EOF
Vagrant.configure(2) do |config|
  config.vm.box = "radiasoft/radtrack-$install_channel"
  config.vm.hostname = "$guest_name"
  config.ssh.forward_x11 = true
  config.vm.synced_folder ENV["HOME"] + "/RadTrack", "/home/vagrant/RadTrack"
  config.vm.network "private_network", ip: "$guest_ip"
  config.vm.provider "virtualbox" do |v|
    v.name = "radtrack"
  end
end
EOF

if ! [[ ' '$(vagrant box list 2>&1) =~ [[:space:]]radiasoft/radtrack-$install_channel[[:space:]] ]] ; then
    #TODO(robnagler) need update protocol
    install_msg 'Downloading virtual machine... (may take an hour)'
    (
        set -e
        cd "$install_tmp"
        install_get_file_foss radiasoft-radtrack.box
        install_msg 'Installing virtual machine... (make take a few minutes)'
        install_log vagrant box add --name radiasoft/radtrack-$install_channel radiasoft-radtrack.box
    )
fi

install_msg 'Starting virtual machine... (may take several minutes)'
# This may fail because the guest additions are out of date
install_log vagrant up < /dev/null || true

install_get_file vagrant-guest-update.sh
rm -f vagrant-guest-update.sh
if ! install_log vagrant ssh -c "sudo dd of=/cfg/vagrant-guest-update.sh" < vagrant-guest-update.sh; then
    install_err 'ERROR: Unable to boot virtual machine'
fi
install_log vagrant ssh -c "sudo 'dd of=bin/vagrant-radtrack; chmod a+rx bin/vagrant-radtrack'" < vagrant-radtrack.sh

# radtrack command
rm -f radtrack
bash=$(type -p bash)
#TODO(robnagler) Check guest additions on every boot.
cat - darwin-radtrack.sh > radtrack <<EOF
#!$bash
echo 'Starting radtrack... (may take a few seconds)'
. '$install_update_conf'
cd '$vm_dir'
EOF
chmod +x radtrack

bashrc=~/.post.bashrc
if [[ ! -r $bashc ]]; then
    bashrc=~/.bashrc
fi
# Remove the old alias if there
perl -pi.bak -e 's/^radtrack\(\)//' "$bashrc"
echo "radtrack() { '$vm_dir/radtrack'; }" >> $bashrc

install_msg 'Before you start radtrack, you will need to:
. ~/.bashrc

Then run radtrack with:
radtrack
'

install_log true Done: install-user.sh
