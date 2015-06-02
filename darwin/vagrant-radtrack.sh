#!/bin/bash
#
# Check for guest updates and then run RadTrack.
#
cd "$(dirname "$0")"
bin=$(pwd)/$(basename "$0")

. ~/.bashrc

set -e

pyenv activate src

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
