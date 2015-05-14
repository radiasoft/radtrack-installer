#!/bin/bash
#
# Functions and vars for installer and update-daemon
#
set -e
assert_subshell() {
    # Subshells are strange with set -e so need to return $? after called to
    # test false at outershell.
    return $?
}

export install_mode=install
if [[ $install_update ]]; then
    export install_mode=update
fi

export install_log_file=/var/log/$install_bundle_name.$install_mode.log
export install_update_log_file=${install_log_file/install/update}

# Note: Keep file name in sync with org.radtrack.update.plist
# This is also stdout/err in org.radtrack.update.plist so there
# may be entries before this first line.
cat <<EOF >> "$install_log_file"
################################################################

Starting: $0 $@
at $(date)
in $(pwd)

$(env | sort)

EOF
# So can be read by trap in install.sh
chown "$install_user" "$install_log_file"

# Development features
# Either pick up $keep/debug from initial command, or inherit install_key/debug
# through environment.
if [[ $keep && $keep != 0 ]]; then
    export install_keep=1
fi

if [[ $debug && $debug != 0 ]]; then
    set -x
    export install_debug=1
fi
debug=

# May not have an install_tmp, but install_lock must exist
export install_ok=$install_lock/ok

install_done() {
    touch "$install_ok"
}

install_err() {
    install_msg "ERROR: $1"
    exit 1
}

install_exit_trap() {
    set +e
    trap - EXIT
    if [[ -e $install_ok ]]; then
        # Ignore any errors from these (install_tmp_delete may not exist)
        install_tmp_delete &> /dev/null
        install_lock_delete &> /dev/null
        exit
    fi
    if [[ $install_update ]]; then
        install_log 'UPDATE ERROR'
        install_update_err
    fi
    install_err 'INSTALLATION FAILED: Please contact support@radtrack.org'
}

install_get_file() {
    local file=$1
    rm -f "$file"
    # TODO(robnagler) encode query
    if ! install_log $install_curl --retry 5 -O "$install_version_url/$file"; then
        install_log ls -l "$file" || true
        return 1
    fi
}

install_log() {
   {
        echo "$(date -u '+%m/%d/%Y %H:%M:%S')" "$@"
        "$@"
   } >> $install_log_file 2>&1
}

install_mkdir() {
    install_log mkdir -p "$1"
}

install_msg() {
    echo "$1"
    install_log : "$1"
}

if [[ ! $install_update ]]; then
    install_host_id=$(ifconfig 2>/dev/null | perl -n -e '/ether ([\w:]+)/ && print(split(/:/, $1)) && exit')
    if [[ ! $install_host_id ]]; then
        export install_host_id=$(date -u '+%Y%m%d%H%M%S')
    fi
    export install_update=
fi
