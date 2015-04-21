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
    echo 'Removing existing RadTrack virtual machine...'
    install_get_file remove-existing-vm.pl
    install_log perl remove-existing-vm.pl
    install_log vagrant box list
fi
echo 'Installing RadTrack virtual machine...'

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
    echo 'Downloading virtual machine... (may take an hour)'
    (
        set -e
        cd "$install_tmp"
        install_get_file_foss radiasoft-radtrack.box
        echo 'Installing virtual machine... (make take a few minutes)'
        install_log vagrant box add --name radiasoft/radtrack radiasoft-radtrack.box
    )
fi

echo 'Starting virtual machine... (may take several minutes)'
# This may fail because the guest additions are out of date
install_log vagrant up || true
if ! install_log vagrant ssh -c true; then
    echo 'ERROR: Unable to boot virtual machine' 1>&2
    exit 1
fi

# Verify guest and host versions agree
host_version=$(perl -e 'print((`vboxmanage --version` =~ /([\d\.]+)/)[0])')
guest_version=$(vagrant ssh -c "sudo perl -e 'print((\`VBoxControl --version\` =~ /([\d\.]+)/)[0])'" 2>/dev/null)
if [[ $host_version != $guest_version ]]; then
    echo 'Updating virtual machine... (may take ten minutes)'
    install_get_file vagrant-guest-update.sh
    install_log vagrant ssh -c "sudo dd of=/cfg/vagrant-guest-update.sh" < vagrant-guest-update.sh
    rm -f vagrant-guest-update.sh
    # Returns false even when it succeeds, if the reload fails (next),
    # then the guest additions didn't get added right (or something else
    # is wrong)
    install_log vagrant ssh -c "sudo bash /cfg/vagrant-guest-update.sh $host_version" || true
    echo 'Restarting virtual machine... (may take a several minutes)'
    install_log vagrant reload
fi

# radtrack command
rm -f radtrack
bash=$(type -p bash)
#TODO(robnagler) Check guest additions on every boot.
cat > radtrack <<EOF
#!$bash
echo 'Starting radtrack... (may take a few seconds)'
cd '$vm_dir'
$install_log
if ! vagrant status 2>&1 | grep -s -q default.*running; then
    echo 'Starting virtual machine... (may take several minutes)'
    install_log vagrant up
fi
install_log exec vagrant ssh -c 'cd ~/src/radiasoft/radtrack; radtrack --beta-test'
EOF
chmod +x radtrack

source_bashrc=false
if [[ -z $(bash -l -c 'type -t radtrack') ]]; then
    if [[ -r ~/.post.bashrc ]]; then
        bashrc=~/.post.bashrc
    else
        bashrc=~/.bashrc
    fi
    echo "radtrack() { '$vm_dir/radtrack'; }" >> $bashrc
    echo 'Before you start radtrack, you will need to:'
    echo '. ~/.bashrc'
fi

echo 'To run radtrack:'
echo 'radtrack'

install_log true Done: install-user.sh
