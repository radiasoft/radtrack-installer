#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the BUNDLE_NAME bundle
#
export install_bundle_name=BUNDLE_NAME
export install_channel=CHANNEL
export install_os_machine=OS_MACHINE
export install_repo=REPO
export install_support=SUPPORT_EMAIL
export install_version=VERSION

x=$(uname -s)/$(uname -m)
export install_target_os_machine=${x,,}

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
export install_user=$(id -u -n)
export install_curl='curl -f -L -s -S'

echo "Installing $install_display_name"
echo 'Please enter your password for this computer when prompted...'
if ! $install_curl "$install_version_url/install-main.sh" || echo exit 1 | sudo -E bash -e; then
    # Need better error message
    echo 'Install failed. Please contact $install_support.' 1>&2
    exit 1
fi
