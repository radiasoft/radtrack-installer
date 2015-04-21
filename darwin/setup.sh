#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# RadTrack installer. See README.md for usage.
#
# Step 2: setup environment and invoke install.sh or update.sh
#
# Required:
#    install_channel=alpha|beta|stable|master
#    install_url=file:|http://...
#    install_user=$(id -u -n)
#
# TODO(robnagler) Need to make multiuser(?)
#
install_mode=install
if [[ $install_update ]]; then
    install_mode=update
fi

install_log_file=/var/log/org.radtrack.$install_mode.log

# Note: Keep file name in sync with org.radtrack.update.plist
# This is stdout/err in org.radtrack.update.plist so empty this way.
# Right now we don't care about log history. Too much trouble with
# rotations and such.
if [[ ! $install_update ]]; then
    cat /dev/null > "$install_log_file"
fi
cat <<EOF >> "$install_log_file"
################################################################
#
# Starting: $0 $@
# at $(date)
#
################################################################
EOF

if [[ $install_debug ]]; then
    set -x
fi

# Ugly, but to keep file consistent
install_err() {
    install_msg "ERROR: $1"
    install_log true "ERROR: $1"
    exit 1
}

install_log() {
   {
        echo "$(date) $@"
        "$@"
   } >> $install_log_file 2>&1
}

install_msg() {
    echo "$1"
}

# $install_tmp is a lockdir. If it can't be created, another install is
# running. All files are known location.
umask 022
install_tmp=/var/tmp/org.radtrack.update
install_ok=$install_tmp/ok
install_pidfile=$install_tmp/pid

# Try to create $install_tmp (lock)
install_conflict=1
for x in 1 2; do
    if mkdir "$install_tmp" 2>/dev/null; then
        install_conflict=
        break
    fi
    install_pid=$(cat "$install_pidfile" 2>/dev/null)
    if [[ ! $install_pid ]]; then
        sleep 2
        continue
    fi
    # Check process exists for our command
    if ps -Eww "$install_pid" 2>&1 | grep -s -q 'bash.*install_channel='; then
        break
    fi
    install_msg 'Removing dead lockfile from previous install'
    rm -rf "$install_tmp"
done

if [[ $install_conflict ]]; then
    install_err 'There appears to be two installers running. Please contact support@radtrack.org'
fi

install_pid=$$
echo -n $install_pid > $install_pidfile
unset install_conflict

install_clean_tmp() {
    set +e
    trap - EXIT
    if [[ -e $install_ok ]]; then
        cd /tmp
        rm -rf "$install_tmp"
        exit
    fi
    if [[ $install_update ]]; then
        install_err 'UPDATE FAILED'
    fi
    install_err 'INSTALLATION FAILED: Please contact support@radtrack.org'
}

# Normal case is exit or error. Don't need to catch signals, because the locking
# mechanism will recover from crashes. If there's a signal, better to stop immediately.
trap install_clean_tmp EXIT
set -e

cd "$install_tmp"
install_timestamp=$(date -u '+%Y%m%d%H%M%S')
install_env_file=$install_tmp/env.sh

if [[ $install_update ]]; then
    cp "$install_update_conf" update.conf
else
    install_host_id=$(ifconfig en0 2>/dev/null | perl -n -e '/ether ([\w:]+)/ && print(split(/:/, $1))')
    if [[ ! $install_host_id ]]; then
        install_host_id=$install_timestamp
    fi
    cat > update.conf <<EOF
export install_channel='$install_channel'
export install_debug='$install_debug'
export install_host_id='$install_host_id'
export install_start_dir='$install_start_dir'
export install_url='$install_url'
export install_user='$install_user'
EOF
    install_update=
fi

cat >> "$install_env_file" <<EOF
. ./update.conf

export install_keep='$install_keep'
export install_log_file='$install_log_file'
export install_ok='$install_ok'
export install_pidfile='$install_pidfile'
export install_timestamp='$install_timestamp'
export install_tmp='$install_tmp'
export install_update='$install_update'
export TMPDIR='$install_tmp'

umask '$(umask)'
if [[ \$install_debug ]]; then
    set -x
fi
EOF

cat >> "$install_env_file" <<'EOF'
set -e

install_done() {
    touch "$install_ok"
}

install_err() {
    install_msg "ERROR: $1"
    install_log true "ERROR: $1"
    exit 1
}

install_get_file() {
    local url=$1
    local silent=
    if ! [[ $url =~ ^.*:// ]]; then
        url=$install_url/$url
    fi
    install_log curl -s -S -L -O "$url"
}

install_get_file_foss() {
    local file=$1
    local url=$file
    if ! [[ $install_url =~ ^file && -r $install_start_dir/$file ]]; then
        url=https://depot.radiasoft.org/foss/$install_channel/darwin/$file
    fi
    install_get_file "$url"
}

install_log() {
   {
        echo "$(date) $@"
        "$@"
   } >> $install_log_file 2>&1
}

install_mkdir() {
    local dir=$1
    mkdir -p "$dir" >& /dev/null || true
}

install_msg() {
    echo "$1"
}

EOF

. "$install_env_file"

if [[ ! $install_update ]]; then
    # Get a copy of this file for install-update-daemon.sh
    install_get_file setup.sh
fi

install_script=$install_mode.sh
install_get_file "$install_script"
. "./$install_script"

install_log true Done: setup.sh
install_done
install_clean_tmp
