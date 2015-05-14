#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the BUNDLE_NAME bundle
#
export install_bundle_name=BUNDLE_NAME
export install_channel=CHANNEL
export install_bundle_display_name=BUNDLE_DISPLAY_NAME
export install_os_machine=OS_MACHINE
export install_repo=REPO
export install_support=SUPPORT
export install_version=VERSION

export install_user=$(id -u -n)

install_err_trap() {
    set +e
    trap - EXIT
    # We don't know what we have so can't use $install_curl, $install_repo, etc.
    curl -T - -L -s "https://panic.radtrack.us/errors/$(date -u +%Y%m%d%H%M%S)-$RANDOM" <<EOF
$0

$(env | sort)

################################################################
# /var/log/$install_bundle_name.install.log

$(cat /var/log/$install_bundle_name.install.log 2>&1)

################################################################
# /var/tmp

$(ls -l /var/tmp 2>&1)
EOF
    exit 1
}
trap install_err_trap EXIT

# Do not use full values, because will be replaced by bundler
if [[ $install_channel =~ ^CHANNE.$ || $install_bundle_name =~ ^BUNDLE_NAM.$ ]]; then
    echo 'You must install from a channel' 1>&2
    exit 1
fi

export install_target_os_machine=$(perl -e 'print(lc(shift))' "$(uname -s)/$(uname -m)")

# Eventually, we'll detect incoming user-agent, and return appropriate URL
# through a redirect to an installer. This is a static file hack for now.
if [[ $install_os_machine != $install_target_os_machine ]]; then
    echo "Unsupported system; expecting $install_os_machine." 1>&2
    exit 1
fi

x=$install_repo/$install_bundle_name/$install_os_machine
export install_version_url=$x/$install_version
export install_channel_url=$x/$install_channel

if [[ $EUID == 0 ]]; then
    echo 'Run this install as an ordinary user (not root/sudo).' 1>&2
    exit 1
fi
export install_user_id=$(id -u -r)
export install_user_full_name=$(id -F)
export install_curl='curl -f -L -s -S'

echo "Installing $install_bundle_display_name"
echo 'Please enter your password for this computer when prompted...'
if ! ($install_curl "$install_version_url/install-main.sh" || echo exit 1) | sudo -E bash -e ${install_debug+-x}; then
    # Need better error message
    echo "Install failed. Please contact $install_support." 1>&2
    exit 1
fi
trap - EXIT
