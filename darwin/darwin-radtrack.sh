#!/bin/bash
#
# Start RadTrack on VM
#
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

run_log() {
    echo "$(date -u '+%m/%d/%Y %H:%M:%S') $1" >> run.log
}
./bivio_vagrant_ssh radtrack_test="$radtrack_test" bin/vagrant-radtrack 2>> run.log \
    | tee -a run.log
e=$?
if (( $e != 0 )); then
    run_log "Bad exit ($e)"
    echo 'RadTrack exited with an error. Last 10 lines of the log are:'
    tail -10 run.log
    exit 1
fi
run_log "exit ok"
