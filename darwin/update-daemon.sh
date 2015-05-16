#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# RadTrack updater. Runs via launchctl (see org.radtrack.update.plist)
#
echo "$0: $(date)"

install_update_err_trap() {
    set +e
    trap - EXIT
    #TODO(robnagler) Encode query(?)
    # We don't know what we have so can't use $install_curl, $install_repo, etc.
    curl -T - -L -s "https://panic.radtrack.us/errors/$(date -u +%Y%m%d%H%M%S)-$RANDOM" <<EOF
$0

$(env | sort)

################################################################
# /opt/org.radtrack/etc/update.conf

$(cat /opt/org.radtrack/etc/update.conf 2>&1)

################################################################
# /var/log/org.radtrack.update.log

$(cat /var/log/org.radtrack.update.log 2>&1)

################################################################
# /var/tmp

$(ls -l /var/tmp 2>&1)

################################################################
# /var/tmp/org.radtrack*

$(ls -al /var/tmp/org.radtrack* 2>&1)
EOF
    # May not exist
    install_lock_delete &>/dev/null
    exit 1
}
trap install_update_err_trap EXIT
set -e

base="$(dirname "$(dirname "$0")")"
. "$base/etc/update.conf"

# Don't use install_get_file, because pulls from install_version_url,
# and we are upgrading. We don't have an $install_tmp at this point.
# update will handle all of that.
$install_curl "$install_channel_url/update.sh" | bash -e
install_lock_delete
trap - EXIT
