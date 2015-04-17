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
# TODO(robnagler) Need to make multiuser
# TODO(robnagler) convert channel tag to commit hash so the
#    separate curl operations are all coming from the same commit

# $install_tmp is a lockdir. If it can't be created, another install is
# running. All files are known location.
umask 022
install_tmp=/var/tmp/org.radtrack.install
install_ok=$install_tmp/ok
install_pidfile=$install_tmp/pid

# Try to create $install_tmp (lock)
install_conflict=1
for x in 1 2; do
    if mkdir -p "$install_tmp" 2>/dev/null; then
        install_conflict=0
        break
    fi
    install_pid=$(cat $install_pidfile 2>/dev/null)
    if [[ ! $install_pid ]]; then
        sleep 2
        continue
    fi
    # Reasonable check that it is our process, not another
    if ps -E "$install_pid" 2>&1 | grep -s -q bash.*install_channel=; then
        break
    fi
    rm -rf "$install_tmp"
done
install_pid=$$
echo -n $install_pid > $install_pidfile

if [[ $install_conflict ]]; then
    echo 'There appears to be two installers running. Please contact support@radtrack.org' 1>&2
    exit 1
fi
unset install_conflict

install_exit_trap() {
    set +e
    local e=$1
    trap - EXIT
    if [[ $e || ! -e $install_ok ]]; then
        if [[ $install_update ]]; then
            curl -L -s "https://radtrack.us/update-error?channel=$install_channel&host_id=$install_host_id&os=$(uname)&user=$install_user" 2>/dev/null | bash &> /dev/null
        else
            echo "INSTALLATION FAILED: Please contact support@radtrack.org" 1>&2
        fi
    else
        cd /tmp
        rm -rf "$install_tmp"
    fi
    exit "$e"
}

# Normal case is exit or error. Don't need to catch signals, because the locking
# mechanism will recover from crashes. If there's a signal, better to stop immediately.
trap install_exit_trap EXIT
set -e

cd "$install_tmp"
install_timestamp=$(date -u '+%Y%m%d%H%M%S')
install_env_file=$install_tmp/env.sh

# Note: Keep file name in sync with org.radtrack.update.plist
install_log_file=/var/log/org.radtrack.install.log
# This is stdout/err in org.radtrack.update.plist so empty this way.
# Right now we don't care about log history. Too much trouble with
# rotations and such.
cat /dev/null > "$install_log_file"

if [[ $install_update ]]; then
    cp "$install_update_conf" .
    install_script=update.sh
else
    install_update=0
    install_home=/opt/org.radtrack
    install_update_conf=$install_home/etc/update.conf
    install_host_id=$(ifconfig en0 2>/dev/null | perl -n -e '/ether ([\w:]+)/ && print(split(/:/, $1))')
    if [[ ! $install_host_id ]]; then
        install_host_id=$install_timestamp
    fi
    install_script=install.sh
    cat > $(basename "$install_update_conf") <<EOF
export install_channel='$install_channel'
export install_host_id='$install_host_id'
export install_url='$install_url'
export install_user='$install_user'
EOF
fi

cat >> "$install_env_file" <<EOF
. './$(basename "$install_update_conf")'

export install_home='$install_home'
export install_log_file='$install_log_file'
export install_ok='$install_ok'
export install_pidfile='$install_pidfile'
export install_timestamp='$install_timestamp'
export install_tmp='$install_tmp'
export install_update='$install_update'
export install_update_conf='$install_update_conf'
export TMPDIR='$install_tmp'

umask '$(umask)'
EOF

cat >> "$install_env_file" <<'EOF'
set -e

install_done() {
    touch "$install_ok"
}

install_err() {
    echo "ERROR: $1" 1>&2
    install_log "ERROR: $1" true
    exit 1
}

install_get_file() {
    local url=$1
    local silent=
    if [[ ! $url =~ ^.*:// ]]; then
        url=$install_url/$url
        # These files are small or local copies (see file://). Big downloads are
        # should have a progress meter
        silent=-s
    fi
    install_log curl "$silent" -L -O "$url"
}

install_get_file_foss() {
    local file=$1
    local url=foss/$file
    if [[ ! ( $install_url =~ ^file && -r $url ) ]]; then
        url=https://depot.radiasoft.org/foss/$install_channel/$file
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
EOF

. "$install_env_file"
install_get_file "$install_script"
. "./$install_script"
