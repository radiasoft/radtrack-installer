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
vm_dir=~/'Library/Application Support/org.radtrack/VM'

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
  config.vm.box = "radiasoft/radtrack"
  config.vm.hostname = "$guest_name"
  config.ssh.forward_x11 = true
  config.vm.synced_folder ENV["HOME"] + "/RadTrack", "/home/vagrant/RadTrack"
  config.vm.network "private_network", ip: "$guest_ip"
  config.vm.provider "virtualbox" do |v|
    v.name = "radtrack"
  end
end
EOF

if ! [[ ' '$(vagrant box list 2>&1) =~ [[:space:]]radiasoft/radtrack[[:space:]] ]] ; then
    #TODO(robnagler) need update protocol
    install_msg 'Downloading virtual machine... (may take an hour)'
    (
        set -e
        cd "$install_tmp"
        install_get_file_foss radiasoft-radtrack.box
        install_msg 'Installing virtual machine... (make take a few minutes)'
        install_log vagrant box add --name radiasoft/radtrack radiasoft-radtrack.box
    )
fi

install_msg 'Starting virtual machine... (may take several minutes)'
# This may fail because the guest additions are out of date
install_log vagrant up < /dev/null || true
if ! install_log vagrant ssh -c true < /dev/null; then
    install_err 'ERROR: Unable to boot virtual machine'
fi

# Verify guest and host versions agree
host_version=$(perl -e 'print((`vboxmanage --version` =~ /([\d\.]+)/)[0])')
guest_version=$(vagrant ssh -c "sudo perl -e 'print((\`VBoxControl --version\` =~ /([\d\.]+)/)[0])'" 2>/dev/null < /dev/null)
if [[ $host_version != $guest_version ]]; then
    install_msg 'Updating virtual machine... (may take ten minutes)'
    install_get_file vagrant-guest-update.sh
    install_log vagrant ssh -c "sudo dd of=/cfg/vagrant-guest-update.sh" < vagrant-guest-update.sh
    rm -f vagrant-guest-update.sh
    # Returns false even when it succeeds, if the reload fails (next),
    # then the guest additions didn't get added right (or something else
    # is wrong)
    install_log vagrant ssh -c "sudo bash /cfg/vagrant-guest-update.sh $host_version" < /dev/null|| true
    install_msg 'Restarting virtual machine... (may take a several minutes)'
    install_log vagrant reload < /dev/null
fi

# radtrack command
rm -f radtrack
bash=$(type -p bash)
#TODO(robnagler) Check guest additions on every boot.
cat > radtrack <<EOF
#!$bash
echo 'Starting radtrack... (may take a few seconds)'
cd '$vm_dir'
if ! vagrant status 2>&1 | grep -s -q 'default.*running'; then
    echo 'Starting virtual machine... (may take several minutes)'
    vagrant up &>/dev/null < /dev/null
fi
exec vagrant ssh -c 'cd ~/src/radiasoft/radtrack; radtrack --beta-test' < /dev/null
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
