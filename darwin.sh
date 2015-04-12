#!/bin/bash
if [[ Darwin != $(uname) ]]; then
    echo 'Unsupported system: This install only works on Mac OS X.' 1>&2
    exit 1
fi

if [[ $EUID == 0 ]]; then
    echo 'Run this instal as an ordinary user (not root).' 1>&2
    exit 1
fi

set -e
install_channel=${channel-beta}

# Temporary directory for downloads. Not in /tmp, because downloading large
# files. Must not contain spaces.
_install_tmp=/var/tmp/radtrack-install-$EUID-$$
rm -rf "$_install_tmp"
install_ok=$_install_tmp/ok
install_host_id=$(ifconfig en0 2>&1 | perl -n -e '/ether ([\w:]+)/ && print(split
(/:/, $1))')

_install_exit_trap() {
    local e=$?
    trap - EXIT
    if [[ $e || ! -e $install_ok ]]; then
        echo "INSTALLATION FAILED: Please contact support@radtrack.org" 1>&2
    else
        cd /tmp
        rm -rf "$_install_tmp"
    fi
    exit "$e"
}
trap _install_exit_trap EXIT
set -e

if [[ -d .git && ${BASH_SOURCE[0]} == darwin.sh ]]; then
    install_src_url=file://$(pwd)/darwin
else
    install_src_url=https://raw.githubusercontent.com/radiasoft/radtrack-installer/$install_channel/darwin
fi

mkdir "$_install_tmp"
cd "$_install_tmp"
export TMPDIR=$_install_tmp

cat > functions.sh <<EOF
install_tmp='$_install_tmp'
install_ok='$install_ok'
install_channel='$install_channel'
install_host_id='$install_host_id'
install_src_url='$install_src_url'
install_user=$(id -u -n)
EOF
cat >> functions.sh <<'EOF'
cd "$(dirname $BASH_SOURCE)"
export TMPDIR=$(pwd)
install_log_file=$_install_tmp/install.log

install_err() {
    echo "ERROR: $1" 1>&2
    exit 1
}

install_done() {
    touch "$install_ok"
}

install_get_file() {
    local url=$1
    if [[ ! $url =~ ^.*:// ]]; then
        url=$install_src_url/$url
    fi
    install_log curl -L -s -O "$url"
    if [[ $EUID == 0 ]]; then
        local file=$(basename "$url")
        chown $install_user "$file"
    fi
}

install_log() {
    {
        echo "$(date) $@"
        "$@"
    } >> $install_log_file 2>&1
}
EOF

. ./functions.sh

install_get_file install.sh
osascript -e 'do shell script "bash install.sh" with administrator privileges'
