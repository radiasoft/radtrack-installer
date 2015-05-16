#!/bin/bash
#
# Try to acquire the lock
#
# Make everything visible
umask 022

export install_lock=/var/tmp/$install_bundle_name.lock
export install_pidfile=$install_lock/pid

export install_conflict=1
for x in 1 2; do
    # mkdir is an atomic operation, even across a network file system
    if mkdir "$install_lock" 2>/dev/null; then
        # Set the trap as close to the directory creation as possible so
        # we don't leave cruft around.
        trap install_lock_delete EXIT
        unset install_conflict
        break
    fi
    install_pid=$(cat "$install_pidfile" 2>/dev/null)
    if [[ ! $install_pid ]]; then
        sleep 2
        continue
    fi
    # Check if this command is already running
    if ps -Eww "$install_pid" 2>&1 | grep -s -q 'bash.*install_bundle_name='; then
        break
    fi
    rm -rf "$install_lock"
done

if [[ $install_conflict ]]; then
    echo "Another installer is running. Please contact $install_support." 1>&2
    exit 1
fi

echo -n "$$" > $install_pidfile
