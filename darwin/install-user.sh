#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Step 3: Running as $install_user setup Vagrant and run patches
#
cd "$(dirname "${BASH_SOURCE[0]}")"

. ./install-functions.sh

# Needs to be ~/', not ~'/. Strange
vm_dir=~/'Library/Application Support/org.radtrack/vagrant'

# Destroy old vagrant
if [[ ! $install_keep && ( -d $vm_dir || $(type -p vagrant) ) ]]; then
    install_msg 'Removing existing virtual machine...'
    install_exec perl remove-existing-vm.pl
fi

install_msg 'Installing virtual machine...'
install_mkdir "$vm_dir"

guest_ip=$(perl find-available-ip.pl 10.13.48)
assert_subshell
install_log "guest_ip=$guest_ip"

# Make RadTrack directory if not already there
install_mkdir ~/RadTrack

cd "$vm_dir"
guest_name=$install_host_id
cat > Vagrantfile <<EOF
Vagrant.configure(2) do |config|
  config.vm.box = "radiasoft/radtrack"
  config.vm.hostname = "$guest_name"
  config.ssh.forward_x11 = true
  config.vm.synced_folder ENV["HOME"] + "/RadTrack", "/home/vagrant/RadTrack"
  config.vm.network "private_network", ip: "$guest_ip"
  config.vm.provider "virtualbox" do |v|
    v.name = "radtrack_v${install_version//./_}_$RANDOM"
  end
end
EOF


if ! [[ ' '$(vagrant box list 2>&1) =~ [[:space:]]radiasoft/radtrack[[:space:]] ]]; then
    #TODO(robnagler) need to decide when to update the virtual machine or
    #   install a new one
    install_msg 'Downloading virtual machine... (may take an hour)'
    (
        cd "$install_tmp"
        install_get_file radiasoft-radtrack.box
        install_msg 'Unpacking virtual machine... (may take a few minutes)'
        #TODO(robnagler) Need better name to be imported from somewhere
        install_exec vagrant box add --name radiasoft/radtrack radiasoft-radtrack.box
        # It's large so remove right away; If error, it's ok, global
        # trap will clean up
        rm -f radiasoft-radtrack.box
    )
    assert_subshell
fi

# programs supporting radtrack
prog=darwin-radtrack
for f in "$prog" bivio_vagrant_ssh; do
    rm -f "$f"
    cp "$install_tmp/$f.sh" "$f"
    chmod +x "$f"
done

#
# radtrack bash function
#
# Update the right bashrc file (consider that
# github.com/biviosoftware/home-env might be in use)
bashrc=~/.post_bivio_bashrc
if [[ ! -r $bashrc ]]; then
    bashrc=~/.bashrc
fi
# ~/.bashrc may not exist
if [[ ! -r $bashrc ]]; then
    echo '#!/bin/bash' > $bashrc
else
    # Remove the old alias if there
    perl -pi.bak -e '/^radtrack\(\)/ && ($_ = q{})' "$bashrc"
fi
echo "radtrack() { '$vm_dir/$prog'; }" >> $bashrc

# profile must source .bashrc so find it in order of bash --login precedence
# and the sourcing of ~/.bashrc if necessary
for f in ~/.bash_profile ~/.bash_login ~/.profile; do
    if [[ -r $f ]]; then
        profile=$f
        break
    fi
done
if [[ ! $profile ]]; then
    profile=~/.bash_profile
    echo '#!/bin/bash' > "$profile"
fi
# Crude test to see if .bashrc is referenced at all. The user doesn't likely
# have a .bash_profile (none by default in Darwin) so this test is good enough,
# especially for repeat installs.
if ! fgrep -s -q '.bashrc' "$profile"; then
    cat >> "$profile" <<'EOF'
if [[ -r ~/.bashrc ]]; then
     . ~/.bashrc
fi
EOF
fi


install_msg 'Updating virtual machine... (may take ten minutes)'
(
    # This also will update the code
    if ! install_exec bash -c '. ~/.bashrc; radtrack_test=1 radtrack'; then
        install_err 'Update failed.'
    fi
) < /dev/null
assert_subshell

cp -f "$install_tmp"/vagrant-radtrack.sh .
./bivio_vagrant_ssh \
    'mv -f /vagrant/vagrant-radtrack.sh ~/bin/vagrant-radtrack; chmod +x ~/bin/vagrant-radtrack' \
    < /dev/null

if [[ $DISPLAY ]]; then
    install_msg '
Before you can start radtrack, you will need to re-read your bash configuration with:

. ~/.bashrc
'
else
    install_msg '
Before you can start radtrack, you must logout and log back in.
'
fi

install_msg 'Then you can run radtrack with the command from a terminal window:

radtrack
'

install_log Done: install-user.sh
