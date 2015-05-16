#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# RadTrack updater. Runs via launchctl (see org.radtrack.update.plist)
#
{{ install_bootstrap_vars }}

echo "$0: $(date)"

install_update_err_trap() {
    set +e
    trap - EXIT
    #TODO(robnagler) Encode query(?)
    # We don't know what we have so can't use $install_curl, $install_repo, etc.
    curl -T - -L -s "$install_panic_url/$(date -u +%Y%m%d%H%M%S)-$RANDOM" <<EOF
$0

$(env | sort)

################################################################
# $install_update_conf

$(cat "$install_update_conf" 2>&1)

################################################################
# $install_update_log_file

$(tail -c 1000 "$install_update_log_file" 2>&1)
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
($install_curl "$install_channel_url/update.sh" || echo exit 1) | bash -e ${install_debug+-x}

set +e
install_lock_delete
trap - EXIT
