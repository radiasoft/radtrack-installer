#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# RadTrack updater. Runs via launchctl (see org.radtrack.update.plist)
#
echo "$0: $(date)"
install_exit_trap() {
    set +e
    trap - EXIT
    #TODO(robnagler) Encode query(?)
    curl -L -s -S "https://panic.radtrack.us/update-error?version=$install_version&channel=$install_channel&host_id=$install_host_id&host_os=$install_host_os&user=$install_user" 2>/dev/null | bash &> /dev/null
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
