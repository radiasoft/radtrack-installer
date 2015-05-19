#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Installer
#
{{ install_bootstrap_vars }}

# Gather data first in the case of error exit
export install_user=$(id -u -n)
export install_user_id=$(id -u -r)
export install_user_full_name=$(id -F)
export install_target_os_machine=$(perl -e 'print(lc(shift))' "$(uname -s)/$(uname -m)")

if [[ $debug ]]; then
    export install_debug=1
fi

if [[ $keep ]]; then
    export install_keep=1
fi

install_err_trap() {
    set +e
    trap - EXIT
    # We don't know what we have so can't use $install_curl, $install_repo, etc.
    curl -T - -L -s "$install_panic_url/$(date -u +%Y%m%d%H%M%S)-$RANDOM" <<EOF
$0 $(date -u)

$(env | sort)

################################################################
# $install_install_log_file

$(cat $install_install_log_file 2>&1)

EOF
    exit 1
}
trap install_err_trap EXIT

if [[ ! $install_channel || ! $install_bundle_name ]]; then
    echo 'You must install from a channel' 1>&2
    exit 1
fi

# Eventually, we'll detect incoming user-agent, and return appropriate URL
# through a redirect to an installer. This is a static file hack for now.
if [[ $install_os_machine != $install_target_os_machine ]]; then
    echo "Unsupported system; expecting $install_os_machine." 1>&2
    exit 1
fi

if [[ $EUID == 0 ]]; then
    echo 'Run this install as an ordinary user (not root/sudo).' 1>&2
    exit 1
fi

echo "Installing $install_bundle_display_name"
echo 'Please enter your password for this computer when prompted...'
if ! ($install_curl "$install_version_url/install-main.sh" || echo exit 1) | sudo -E bash -e ${install_debug+-x}; then
    # Need better error message
    echo "Install failed. Please contact $install_support." 1>&2
    exit 1
fi
trap - EXIT
