#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Step 2: Running as root
#
d=$(dirname "${BASH_SOURCE[0]}")
cd "$d"
unset d

. ./functions.sh

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
    local url=https://depot.radiasoft.org/foss/$dmg
    get_boot_volume
    echo "Downloading $pkg... (speed depends on Internet connection)"
    # Needed for XQuartz, because dmg mounts as /Volumes/XQuartz-<version>
    vol=$(echo /Volumes/$pkg*)
    if [[ -n $vol ]]; then
        install_log hdiutil unmount "$vol"
    fi
    http_get "$url"
    install_log hdiutil mount "$dmg"
    vol=$(echo /Volumes/"$pkg"*)
    echo "Installing $pkg... (may take a minute or two)"
    local pkg_file=$(echo "$vol"/*.pkg)
    if [[ -n $pkg_file ]]; then
        install_err "$dmg" did not contain "$pkg".
    fi
    install_log installer -package $pkg_file -target "$boot_volume"
    install_log hdiutil unmount "$vol"
    rm -f "$dmg"
}

echo 'Checking for 3rd party packages to install...'
if [[ ! -d /Applications/Utilities/XQuartz.app ]]; then
    install_pkg XQuartz
fi
if ! type -p VBoxManage &> /dev/null; then
    install_pkg VirtualBox
fi
if ! type -p vagrant &> /dev/null]; then
    install_pkg Vagrant
fi

install_get_file install-user.sh
sudo -u "$install_user" install-user.sh
install_done
