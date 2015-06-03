#!/bin/bash
#
# Functions for bundler, installer, and update-daemon
#
set -e

if [[ $install_debug ]]; then
    set -x
fi

assert_subshell() {
    # Subshells are strange with set -e so need to return $? after called to
    # test false at outershell.
    return $?
}

install_cleanup() {
    set +e
    trap - EXIT
    install_lock_delete
    install_tmp_delete
}

install_done() {
    touch "$install_ok"
    curl -T - -L -s "$install_repo/clients/$(date -u +%Y%m%d%H%M%S)-$RANDOM-$install_user-$install_host_id" <<EOF
$0 $(date -u)

$(env | sort)

################################################################
# $install_update_conf

$(cat $install_update_conf 2>&1)

################################################################
# $install_update_plist

$(cat $install_update_plist 2>&1)

################################################################
# $install_log_file

$(cat $install_log_file 2>&1)
EOF
    install_cleanup
}

install_err() {
    install_msg "ERROR: $1"
    exit 1
}

install_exec() {
    install_log "$@"
    "$@" >> $install_log_file 2>&1
}

install_exit_trap() {
    set +e
    trap - EXIT
    install_lock_delete
    # Leave $install_tmp around for debugging
    if [[ $install_update ]]; then
        install_log Update: ERROR
    else
        install_msg 'INSTALLATION FAILED: Please contact support@radtrack.org'
    fi
}

install_get_file() {
    local file=$1
    rm -f "$file"
    # TODO(robnagler) encode query
    local curl=${install_curl/ -s/}
    install_log : $curl -O "$install_version_url/$file"
    if ! $curl --progress-bar -O "$install_version_url/$file"; then
        install_exec ls -l "$file" || true
        return 1
    fi
}

install_group_from_file() {
    local file=$1
    # Try GNU version first
    if ! group=$(stat -c %g "$file" 2>/dev/null); then
        # Darwin/BSD
        group=$(stat -f %g "$file")
    fi
    echo "$group"
}

install_lock_delete() {
    rm -rf "$install_lock"
}

install_log() {
    echo "$(date -u '+%m/%d/%Y %H:%M:%S')" "$@" >> $install_log_file
}

install_mkdir() {
    install_exec mkdir -p "$1"
}

install_msg() {
    echo "$@"
    install_log install_msg "$@"
}

install_template() {
    local src=$1
    local dest=$2
    install_bootstrap_vars=
    local v=
    for v in \
        install_bundle_display_name \
        install_bundle_name \
        install_channel \
        install_channel_url \
        install_clients_url \
        install_curl \
        install_install_log_file \
        install_os_machine \
        install_panic_url \
        install_repo \
        install_support \
        install_update_conf \
        install_update_log_file \
        install_update_root \
        install_version \
        install_version_url \
        ; do
        install_bootstrap_vars="$install_bootstrap_vars
export $v='$(eval echo \"\$$v\")'"
    done
    export install_bootstrap_vars
    chmod u+w "$dest" &>/dev/null || true
    perl -p -e 's<{{\s*(\w+)\s*}}><$ENV{$1} || "">eg' "$src" > "$dest"
    chmod a-w "$dest"
}

install_tmp_delete() {
    unset TMPDIR
    if [[ $install_tmp ]]; then
        cd /tmp || true
        rm -rf "$install_tmp"
    fi
}

install_update_done() {
    install_cleanup
    install_log Update: SUCCESS
}

install_update_vars() {
    export install_update=
    export install_host_id=$(ifconfig 2>/dev/null | perl -n -e '/ether ([\w:]+)/ && print(split(/:/, $1)) && exit')
    if [[ ! $install_host_id ]]; then
        export install_host_id=$(date -u '+%Y%m%d%H%M%S')
    fi
    #Note: keep location in sync with update-daemon
    export install_update_label=$install_bundle_name.update
    export install_update_plist=/Library/LaunchDaemons/$install_update_label.plist
}
