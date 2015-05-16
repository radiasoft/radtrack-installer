#!/bin/bash
#
# Start RadTrack on VM
#
if [[ $install_debug ]]; then
    set -x
fi

echo 'Starting RadTrack'
cd "$(dirname "$0")"
cat <<EOF >> run.log
################################################################
#
# Starting: $0
# at $(date)
#
################################################################
EOF

run_err_trap() {
    set +e
    trap - EXIT
    #TODO(robnagler) Encode query(?)
    # We don't know what we have so can't use $install_curl, $install_repo, etc.
    curl -T - -L -s "https://panic.radtrack.us/errors/$(date -u +%Y%m%d%H%M%S)-$RANDOM" <<EOF
$0

$(env | sort)

################################################################
# run.log

$(cat "/opt/org.radtrack/etc/update.conf" 2>&1)

################################################################
# /var/log/org.radtrack.update.log

$(cat run.log 2>&1)
EOF
    # May not exist
    install_lock_delete &>/dev/null
    exit 1
}

run_log() {
    echo "$(date -u +%Y%m%dT%H%M%SZ) $1" >> run.log
}

./bivio_vagrant_ssh radtrack_test="$radtrack_test" bin/vagrant-radtrack 2>> run.log \
    | tee -a run.log
e=$?

if (( $e != 0 )); then
    run_log "Bad exit ($e)"
    echo 'RadTrack exited with an error. Last 10 lines of the log are:' 1>&2
    tail -10 run.log 1>&2
    exit 1
elif tail -2 run.log | grep -s -q 'cannot connect.*X'; then
    if [[ $DISPLAY ]]; then
        echo 'The display failed to connect to X server. Please contact support@radtrack.org.' 1>&2
        exit 1
    fi
    echo 'XQuartz is not configured properly. Please reboot and try again' 1>&2
    exit 1
fi
run_log "exit ok"
trap - EXIT
