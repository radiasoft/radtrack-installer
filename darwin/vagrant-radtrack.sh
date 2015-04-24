#!/bin/bash
#
# Check for guest updates and then run RadTrack.
#
cd "$(dirname "$0")"
bin=$(pwd)/$(basename "$0")

. ~/.bashrc

set -e

if [[ $vbox_version ]]; then
    # If the guest was updated, it will exit true, otherwise false. There
    # may be a problem with updating the guest so any non-zero exit is like
    # a non-update. Only reasonable test is that we were successful.
    if sudo vbox_version="$vbox_version" bash "/cfg/vagrant-guest-update.sh"; then
        exit 33
    fi
fi

pyenv activate radtrack
#TODO(robnagler) test that it is a synced folder. Synced folders may fail.
cd ~/RadTrack

if [[ ! $radtrack_test ]]; then
    # This flag is misnamed. It's really "show fewer tabs"
    radtrack --beta-test < /dev/null 1>&2
elif DISPLAY= radtrack 2>&1 | grep -s -q 'cannot connect.*X'; then
    exit 0
else
    DISPLAY= radtrack 1>&2
    exit 99
fi
