#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Step 3: Running as $install_user setup Vagrant and run patches
#
d=$(dirname "${BASH_SOURCE[0]}")
cd "$d"
unset d

./env.sh

# Separate directory
vm_dir=~/'Library/Application Support/org.radtrack/VM'

# Destroy old vagrant
if [[ -d  $vm_dir || -n $(type -p vagrant) ]]; then
    echo 'Removing existing RadTrack installation...'
    install_log perl "$vm_dir" <<'EOF'
    use warnings;
    use strict;
    my($vm_dir) = $ARGV[0];
    foreach my $line (`vagrant global-status --prune 2>&1`) {
        next
            unless $line =~ m{default +virtualbox +\w+ +(/.+)}
            && -d $1;
        my($dir) = $1;
        next
            unless chdir($dir)
            && ( $vm_dir eq $dir
            || open(IN, 'Vagrantfile')
            && <IN> =~ m{vm.box\s*=\s*(?:biviosoftware|radiasoft)/radtrack"} );
        system([qw(vagrant destroy --force)]);
        if (glob('*') > 5) {
            print(STDERR "$dir: not removing VM directory (>5 files)\n");
            next;
        }
        chdir($ENV{HOME});
        system(qw(rm -rf), $dir);
    }
EOF
    vagrant box remove biviosoftware/radtrack &> /dev/null || true
    vagrant box remove radiasoft/radtrack &> /dev/null || true
fi
echo 'Installing RadTrack...'

install_log install_mkdir "$vm_dir"
cd $vm_dir

guest_ip=10.13.48.2
guest_name=$install_host_id
cat > Vagrantfile <<EOF
# -*- mode: ruby -*-
# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "radiasoft/radtrack"
  config.vm.hostname = "$guest_name.radtrack.us"
  config.ssh.forward_x11 = true
  config.vm.synced_folder ENV["HOME"] + "/RadTrack", "/home/vagrant/RadTrack"
  config.vm.network "private_network", ip: "$guest_ip"
end
EOF
fi
if [[ ' '$(vagrant box list 2>&1) =~ [[:space:]]radiasoft/radtrack[[:space:]] ]] ; then
    echo 'Checking virtual machine update... (may take an hour if out of date)'
    install_log vagrant box update
else
    echo 'Downloading virtual machine... (may take an hour)'
    install_log vagrant box add https://atlas.hashicorp.com/radiasoft/boxes/radtrack
fi
echo 'Starting virtual machine... (may take several minutes)'
install_log vagrant up

# radtrack command
rm -f radtrack
bash=$(type -p bash)
cat > radtrack <<EOF
#!$bash
echo 'Starting radtrack... (may take a few seconds)'
cd '$vm_dir'
$install_log
if ! vagrant status 2>&1 | grep -s -q default.*running; then
    echo 'Starting virtual machine... (may take a minute)'
    install_log vagrant up
fi
install_log exec $vagrant_ssh -c 'radtrack --beta-test'
EOF
chmod +x radtrack
source_bashrc=false
if [[ -z $(bash -l -c 'type -t radtrack') ]]; then
    echo 'radtrack() { ~/RadTrack/.vm/radtrack; }' >> ~/.bashrc
    echo 'Before you start radtrack, you will need to:'
    echo '. ~/.bashrc'
fi
echo 'To run radtrack:'
echo 'radtrack'
