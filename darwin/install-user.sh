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
    install_msg 'Removing existing virtual machine...'
    install_get_file remove-existing-vm.pl
    install_log perl remove-existing-vm.pl
fi
install_msg 'Installing virtual machine...'

install_log install_mkdir "$vm_dir"
cd "$vm_dir"

#TODO(robnagler) dynamically assign
guest_ip=10.13.48.42
guest_name=$install_host_id
cat > Vagrantfile <<EOF
Vagrant.configure(2) do |config|
  config.vm.box = "radiasoft/radtrack"
  config.vm.hostname = "$guest_name"
  config.ssh.forward_x11 = true
  config.vm.synced_folder ENV["HOME"] + "/RadTrack", "/home/vagrant/RadTrack"
  config.vm.network "private_network", ip: "$guest_ip"
end
EOF

if ! [[ ' '$(vagrant box list 2>&1) =~ [[:space:]]radiasoft/radtrack[[:space:]] ]] ; then
    #TODO(robnagler) need to decide when to update the virtual machine or
    #   install a new one
    install_msg 'Downloading virtual machine... (may take an hour)'
    (
        set -e
        cd "$install_tmp"
        install_get_file_foss radiasoft-radtrack.box
        install_msg 'Unpacking virtual machine... (make take a few minutes)'
        install_log vagrant box add --name radiasoft/radtrack radiasoft-radtrack.box
        # It's large so remove right away
        rm -f radiasoft-radtrack.box
    )
fi

install_msg 'Starting virtual machine... (may take several minutes)'
# This may fail because the guest additions are out of date
install_log vagrant up < /dev/null || true

install_get_file vagrant-guest-update.sh
if ! install_log vagrant ssh -c "sudo dd of=/cfg/vagrant-guest-update.sh" < vagrant-guest-update.sh; then
    install_err 'ERROR: Unable to boot virtual machine'
fi
rm -f vagrant-guest-update.sh

install_get_file vagrant-radtrack.sh
install_log md5 vagrant-radtrack.sh
install_log vagrant ssh -c "dd of=bin/vagrant-radtrack; chmod a+rx bin/vagrant-radtrack; md5sum bin/vagrant-radtrack" < vagrant-radtrack.sh
rm -f vagrant-radtrack.sh

# radtrack command
prog=$install_host_os-radtrack
rm -f "$prog"
bash=$(type -p bash)
#TODO(robnagler) Check guest additions on every boot.
install_get_file "$prog.sh"
cat - "$prog.sh" > "$prog" <<EOF
#!$bash
echo 'Starting radtrack... (may take a few seconds)'
. '$install_update_conf'
cd '$vm_dir'
EOF
chmod u+rx "$prog"
rm -f "$prog".sh

# Update the right bashrc file (see biviosoftware/home-env)
bashrc=~/.post.bashrc
if [[ ! -r $bashrc ]]; then
    bashrc=~/.bashrc
fi
# Remove the old alias if there
perl -pi.bak -e '/^radtrack\(\)/ && ($_ = q{})' "$bashrc"
echo "radtrack() { '$vm_dir/$prog'; }" >> $bashrc

install_msg 'Updating virtual machine... (may take several minutes)'
(
    # This also will update the code
    if ! install_log bash -l -c 'radtrack_test=1 radtrack'; then
        install_err 'Update failed.'
    fi
) < /dev/null || exit $?

install_msg 'Before you start radtrack, you will need to:
. ~/.bashrc

Then run radtrack with:
radtrack
'

install_log true Done: install-user.sh
