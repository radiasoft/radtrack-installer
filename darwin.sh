#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# RadTrack installer. See README.md for usage.
#
# Dynamically edited by the dist builder so don't change this line:
install_http_url=${url-DIST_URL}

if [[ Darwin != $(uname) ]]; then
    echo 'Unsupported system: This install only works on Mac OS X.' 1>&2
    exit 1
fi
install_host_os=darwin

if [[ $EUID == 0 ]]; then
    echo 'Run this install as an ordinary user (not root).' 1>&2
    exit 1
fi
install_user=$(id -u -n)

case $channel in
    alpha|beta|deveop|master|stable)
        export install_channel=$channel
        ;;
    *)
        echo 'Invalid or no channel specified.' 1>&2
        echo "Usage: channel=(alpha|beta|stable) $0" 1>&2
        exit 1
        ;;
esac

echo Installing RadTrack...

# Development features
install_keep=
if [[ $keep && $keep != 0 ]]; then
    install_keep=1
fi

install_debug=
if [[ $debug && $debug != 0 ]]; then
    set -x
    install_debug=1
fi

install_start_dir=$(pwd)
if [[ $install_debug && $install_start_dir =~ radiasoft/radtrack-installer ]]; then
    if ! [[ $install_start_dir =~ /$install_host_os$ ]]; then
        cd "$install_host_os"
        install_start_dir=$(pwd)
    fi
    install_url=file://$install_start_dir
else
    install_url=$install_http_url
fi

# No spaces or special characters in name
tmpfile=/tmp/radtrack-install-$(date -u '+%Y%m%d%H%M%S')

if [[ ! $install_version ]]; then
    install_version=$install_channel
fi
cat > "$tmpfile" <<EOF
rm -f "\$0"
export install_channel='$install_channel'
export install_debug='$install_debug'
export install_host_os='$install_host_os'
export install_http_url='$install_http_url'
export install_keep='$install_keep'
export install_start_dir='$install_start_dir'
export install_url='$install_url'
export install_user='$install_user'
export install_version='$install_version'

EOF
curl -s -S -L "$install_url/setup.sh" >> "$tmpfile"
if [[ $? != 0 || $(tail -1 "$tmpfile") =~ ^Not.Found ]]; then
    cat <<EOF
ERROR: Unable to retrieve installer from:

$install_url/setup.sh

We apologize for this error. Please contact support@radtract.org.
EOF
    exit 1
fi

echo 'Please enter your Mac login password when prompted'
sudo bash "$tmpfile"
rm -f "$tmpfile"
