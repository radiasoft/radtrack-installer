#!/bin/bash
#
# Step 3: Running as $install_user
#

# Separate directory
vm_dir=~/RadTrack/.vm
if [[ -d  $vm_dir || -n $(type -p vagrant) ]]; then
    echo 'Removing existing RadTrack installation...'
    install_log perl -w <<'EOF'
    use strict;
    foreach my $line (`vagrant global-status --prune 2>&1`) {
        next
            unless $line =~ m{default +virtualbox +\w+ +(/.+)}
            && -d $1;
        my($dir) = $1
        next
            unless chdir($dir)
            && open(IN, 'Vagrantfile')
            && <IN> =~ m{vm.box.*biviosoftware/radtrack"};
        system([qw(vagrant destroy --force)]);
        chdir($ENV{HOME})
        system([qw(rm -rf)], $dir);
    }
EOF
else
    echo 'Installing RadTrack...'
fi

set time zone
set tmp directory

install_log mkdir -p "$vm_dir"
cd $vm_dir

# Always reconfigure vagrant
cat > Vagrantfile <<'EOF'
# -*- mode: ruby -*-
# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "biviosoftware/radtrack"
  config.vm.hostname = "radtrack"
  config.ssh.forward_x11 = true
  config.vm.synced_folder ENV["HOME"] + "/RadTrack", "/home/vagrant/RadTrack"
end
EOF
fi
if [[ ' '$(vagrant box list 2>&1) =~ [[:space:]]biviosoftware/radtrack[[:space:]] ]] ; then
    echo 'Checking virtual machine update... (may take an hour if out of date)'
    install_log vagrant box update
else
    echo 'Downloading virtual machine... (may take an hour)'
    install_log vagrant box add https://atlas.hashicorp.com/biviosoftware/boxes/radtrack
fi
echo 'Starting virtual machine... (may take several minutes)'
install_log vagrant up

# radtrack command
rm -f radtrack
bash=$(type -p bash)
cat > radtrack <<EOF
#!$bash
echo 'Starting radtrack... (may take a few seconds)'
cd $vm_dir
$install_log
if ! vagrant status 2>&1 | grep -s -q default.*running; then
    echo 'Starting virtual machine... (may take a minute)'
    install_log vagrant up
fi
install_log exec vagrant ssh -c 'radtrack --beta-test'
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
