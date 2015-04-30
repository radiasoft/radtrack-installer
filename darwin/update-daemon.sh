#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# RadTrack updater. Runs via launchctl (see org.radtrack.update.plist)
#
echo "$0: $(date)"

install_update_err() {
    set +e
    trap - EXIT
    #TODO(robnagler) Encode query(?)
    # We don't know what we have so can't use $install_curl, $install_repo, etc.
    curl -f -L -s "https://panic.radtrack.us/update-error?version=$install_version&channel=$install_channel&host_id=$install_host_id&user=$install_user" 2>/dev/null | bash &> /dev/null
    # May not exist
    install_lock_delete &>/dev/null
    exit 1
}
trap install_update_err EXIT
set -e

base="$(dirname "$(dirname "$0")")"
. "$base/etc/update.conf"

# Don't use install_get_file, because pulls from install_version_url,
# and we are upgrading. We don't have an $install_tmp at this point.
# update will handle all of that.
install_curl "$install_channel_url/update.sh" | bash -e
trap - EXIT
install_lock_delete
