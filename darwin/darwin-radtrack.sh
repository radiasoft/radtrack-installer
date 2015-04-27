#
# Don't run
# Start RadTrack on VM
#
cat <<EOF >> run.log
################################################################
#
# Starting: $0
# at $(date)
#
################################################################
EOF

bivio_vagrant_ssh radtrack_test="$radtrack_test" bin/vagrant-radtrack 2>> run.log \
    | tee -a run.log
e=$?
if (( $e != 0 )); then
    run_log "Bad exit ($e)"
    echo 'RadTrack exited with an error. Last 10 lines of the log are:'
    tail -10 run.log
    exit 1
else
    run_log 'exit ok'
fi
