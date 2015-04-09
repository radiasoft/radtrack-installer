#!/bin/bash
if [[ Darwin != $(uname) ]]; then
    echo 'Unsupported system: This installer only works on Mac OS X.' 1>&2
    exit 1
fi

if [[ $EUID == 0 ]]; then
    echo 'Run this installer as an ordinary user (not root).' 1>&2
    exit 1
fi

set -e
export TMP=/var/tmp/radtrack-installer-$EUID-$$
rm -rf "$TMP"

# Clean up safely
_radtrack_installer_exit() {
    local e=$?
    trap - EXIT
    if [[ $e ]]; then
        echo "INSTALLATION FAILED: Please contact support@radtrack.net" 1>&2
    fi
    cd /tmp
    rm -rf "$TMP"
    exit "$e"
}
trap _radtrack_installer_exit EXIT
set -e

if [[ -d .git && ${BASH_SOURCE[0]} == darwin.sh ]]; then
    install_src_url=file://$(pwd)/darwin
else
    install_src_url=https://raw.githubusercontent.com/radiasoft/radtrack-installer/master/darwin
fi

mkdir "$TMP"
cd "$TMP"

cat > functions.sh <<EOF
install_src_url='$installer_src_url'
install_user=$(id -u -n)
EOF
cat >> functions.sh <<'EOF'
_install_back=$(pwd)
cd "$(dirname $BASH_SOURCE)"
export TMP=$(pwd)
cd _install_back
unset _install_back
install_log_file=$TMP/install.log

install_err() {
    echo "ERROR: $1" 1>&2
    exit 1
}

install_log() {
    {
        echo "$(date) $@"
        "$@"
    } >> $install_log_file 2>&1
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
EOF

. ./functions.sh

install_get_file install.sh
bash=$(type -p bash)
osascript -e "do shell script '$bash $(pwd)/install.sh' with administrator privileges"
