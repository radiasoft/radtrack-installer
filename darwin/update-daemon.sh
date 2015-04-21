#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# RadTrack updater. Runs via launchctl (see org.radtrack.update.plist)
#
echo "$0: $(date)"
install_exit_trap() {
    set +e
    trap - EXIT
    # Encode query
    curl -L -s -S "https://radtrack.us/update-error?channel=$install_channel&host_id=$install_host_id&os=$(uname)&user=$install_user" 2>/dev/null | bash &> /dev/null
    exit 1
}
trap install_exit_trap EXIT
set -e

base="$(dirname "$(dirname "$0")")"
export install_update_conf=$base/etc/update.conf
. "$install_update_conf"
export install_update=1
bash -e "$base/lib/setup.sh"
trap - EXIT
