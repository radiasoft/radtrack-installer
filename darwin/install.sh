#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Step 3: Running as root install packages
#
shopt -s nullglob

boot_volume=
get_boot_volume() {
    if [[ -n "$_boot_volume" ]]; then
        return
    fi
    local f
    for f in /Volumes/*; do
        # Rigid regex, but need to be sure is mounted on root.
        # Assertion at end means
        local re='Mounted: +Yes[[:space:]]+Mount Point: +/'$'\n'
        if [[ $(diskutil info "$f" 2>&1) =~ $re ]]; then
            boot_volume="$f"
            return
        fi
    done
    install_err 'Unable to find boot volume'
}

install_pkg() {
    local pkg=$1
    local dmg=$pkg.dmg
    get_boot_volume

    install_msg "Downloading $pkg... (speed depends on Internet connection)"
    # Needed for XQuartz, because dmg mounts as /Volumes/XQuartz-<version>
    vol=$(echo /Volumes/$pkg*)
    if [[ -n $vol ]]; then
        install_log hdiutil unmount "$vol"
    fi
    install_get_file_foss "$dmg"

    install_msg "Installing $pkg... (may take a minute or two)"
    install_log hdiutil mount "$dmg"
    vol=$(echo /Volumes/"$pkg"*)
    local pkg_file=$(echo "$vol"/*.pkg)
    if [[ -n $pkg_file ]]; then
        install_err "$dmg" did not contain "$pkg".
    fi
    install_log installer -package $pkg_file -target "$boot_volume"
    install_log hdiutil unmount "$vol"
    rm -f "$dmg"
}

install_msg 'Checking for 3rd party packages to install...'
if [[ ! -d /Applications/Utilities/XQuartz.app ]]; then
    install_pkg XQuartz
fi
if ! type -p VBoxManage &> /dev/null; then
    install_pkg VirtualBox
fi
if ! type -p vagrant &> /dev/null; then
    install_pkg Vagrant
fi

install_get_file install-update-daemon.sh
#. ./install-update-daemon.sh

# Last step, because run as the user. The recursive chown could allow
# a local privilege escalation attack, since we return as root after running
# as the user, and run files in this directory.
install_get_file install-user.sh
# Safety precaution: don't use "." in the chown. Only give full files
chown -R "$install_user" "$install_tmp" "$install_log_file"
sudo -u "$install_user" bash -e "$install_tmp/install-user.sh"

install_log true Done: install.sh
