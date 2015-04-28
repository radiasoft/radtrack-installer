#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Step 3: Running as $install_user setup Vagrant and run patches
#
d=$(dirname "${BASH_SOURCE[0]}")
cd "$d"
unset d

. ./install-functions.sh

# Needs to be ~/', not ~'/. Strange
vm_dir=~/'Library/Application Support/org.radtrack/vagrant'

# Destroy old vagrant
if [[ ! $install_keep && ( -d $vm_dir || $(type -p vagrant) ) ]]; then
    install_msg 'Removing existing virtual machine...'
    install_log perl remove-existing-vm.pl
fi

install_msg 'Installing virtual machine...'
install_log install_mkdir "$vm_dir"
cd "$vm_dir"

# Arbitrary network, which isn't likely to collide with some intranet
guest_net=10.13.48
dclare -i i=$(perl -e 'print(int(rand(50)) + 60)')
guest_ip=
while (( $i < 255 )); do
    x=$guest_net.$i
    if ! ( echo > /dev/tcp/$x/22 ) >& /dev/null; then
        guest_ip=$x
        break
    fi
    i+=1
done

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
        install_get_file radiasoft-radtrack.box
        install_msg 'Unpacking virtual machine... (make take a few minutes)'
        #TODO(robnagler) Need better name to be imported from somewhere
        install_log vagrant box add --name radiasoft/radtrack radiasoft-radtrack.box
        # It's large so remove right away; If error, it's ok, global
        # trap will clean up
        rm -f radiasoft-radtrack.box
    ) || exit 1
fi

# radtrack command
prog=darwin-radtrack
chmod u+rx "$prog"
rm -f "$prog".sh

# Update the right bashrc file (see github.com/biviosoftware/home-env)
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
