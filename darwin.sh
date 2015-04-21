#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# RadTrack installer. See README.md for usage.
#
if [[ Darwin != $(uname) ]]; then
    echo 'Unsupported system: This install only works on Mac OS X.' 1>&2
    exit 1
fi

if [[ $EUID == 0 ]]; then
    echo 'Run this install as an ordinary user (not root).' 1>&2
    exit 1
fi

install_channel=
case $channel in
    alpha|beta|stable)
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

install_user=$(id -u -n)

install_start_dir=$(pwd)
if [[ $install_debug && $install_start_dir =~ radiasoft/radtrack-installer ]]; then
    if ! [[ $install_start_dir =~ /darwin$ ]]; then
        cd darwin
        install_start_dir=$(pwd)
    fi
    install_url=file://$install_start_dir
else
    #TODO(robnagler) Pull from radtrack.us
    install_url=https://raw.githubusercontent.com/radiasoft/radtrack-installer/$install_channel/darwin
fi

# No spaces or special characters in name, because of osascript call below
tmpfile=/tmp/radtrack-install-$(date -u '+%Y%m%d%H%M%S')

cat > "$tmpfile" <<EOF
rm -f "\$0"
export install_channel='$install_channel'
export install_debug='$install_debug'
export install_keep='$install_keep'
export install_url='$install_url'
export install_user='$install_user'
export install_start_dir='$install_start_dir'

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

if [[ -t 1 ]]; then
    tty_out=' > /dev/tty'
fi

echo 'Please give administrator privileges in the popup window'
osascript -e "do shell script \"bash $tmpfile$tty_out 2>&1\" with administrator privileges"
