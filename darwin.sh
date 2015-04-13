#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# RadTrack installer. See README.md for usage.
#
# Step 1: invoke darwin/boot.sh
#
if [[ Darwin != $(uname) ]]; then
    echo 'Unsupported system: This install only works on Mac OS X.' 1>&2
    exit 1
fi

if [[ 0 == $EUID ]]; then
    echo 'Run this install as an ordinary user (not root).' 1>&2
    exit 1
fi

case $channel in
    alpha|beta|stable)
        export install_channel=$channel
        ;;
    *)
        echo 'Invalid or no channel specified.' 1>&2
        echo "Usage: channel=(alpha|beta|stable) $0" 1>&2
        exit 1
        ;;
fi

if [[ $(pwd) =~ /radtrack-installer$ && -d .git ]]; then
    install_url=file://$(pwd)/darwin
else
    install_url=https://raw.githubusercontent.com/radiasoft/radtrack-installer/$install_channel/darwin
fi
install_user=$(id -u -n)

# No spaces or special characters in name, because of osascript call below
tmpfile=/tmp/radtrack-install-$(date -u '+%Y%m%d%H%M%S')

cat > $tmpfile <<EOF
rm -f "\$0"
export install_channel='$install_channel'
export install_user='$install_user'
export install_url='$install_url'
curl -s -L '$install_url/setup.sh' | bash
EOF

osascript -e "do shell script \"bash $tmpfile\" with administrator privileges"
