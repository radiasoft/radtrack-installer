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

run_log() {
    echo "#### $1: $(date) ####" >> run.log
}
if ! vagrant status 2>&1 | grep -s -q 'default.*running'; then
    echo 'Starting virtual machine... (may take several minutes)'
    vagrant up &>/dev/null < /dev/null
    run_log 'Boot VM'
fi

vbox_version=$(perl -e 'print((`vboxmanage --version` =~ /([\d\.]+)/)[0])')

declare -i reload_count=0
declare -i restart_count=0
cmd="radtrack_test='$radtrack_test' install_channel='$install_channel' vbox_version='$vbox_version' bin/vagrant-radtrack"
for count in 1 2 3; do
    run_log "Starting: $cmd"
    vagrant ssh -c "$cmd" < /dev/null >> run.log 2>&1
    exit=$?
    # Keep exit codes in sync with vagrant-radtrack.sh
    case $exit in
        0)
            exit 0
            ;;
        22)
            if (( $restart_count > 1 )); then
                run_log 'Too many program restarts'
                echo 'Program restart loop. Please contact support@radiasoft.org'
                exit 1
            fi
            echo 'Restarting program after software update... (may take a minute)'
            restart_count+=1
            run_log 'Program Restart'
            ;;
        33)
            if (( $reload_count >= 1 )); then
                run_log 'Too many VM reloads'
                echo 'Unable to update virtual machine. Please contact support@radiasoft.org'
                exit 1
            fi
            echo 'Restarting virtual machine... (may take a several minutes)'
            vagrant reload < /dev/null &> /dev/null
            reload_count+=1
            run_log 'VM Reload'
            ;;
        *)
            run_log "Bad exit ($exit)"
            echo 'RadTrack exited with an error. Last 10 lines of the log are:'
            if [[ $radtrack_test ]]; then
                tail -10 run.log
            fi
            exit 1
    esac
done
