#!/bin/bash
#
# Run RadTrack pulling out latest version from the install_channel,
# checking guest updates, and verifying this program is up to date.
#
cd "$(dirname "$0")"
bin=$(dirname "$(pwd)")/$(basename "$0")

. ~/.bashrc

set -e
if [[ $install_channel ]]; then
    cd ~/src/radiasoft
    #TODO(robnagler) remove as soon as vm rebuilt with
    #    radtrack-installer pulled out
    if [[ ! -d radtrack-installer ]]; then
        git clone ${BIVIO_GIT_SERVER-https://github.com}/radiasoft/radtrack-installer
    fi

    for f in radtrack radtrack-installer; do
        (
            set -e
            cd "$f"
            git fetch -q
            git checkout -q "tags/$install_channel"
        ) || exit $?
    done

    # Has this program changed?
    src_dir=~/src/radiasoft/radtrack-installer/darwin
    src=$src_dir/vagrant-radtrack.sh
    src_md5=( $(md5sum "$src") )
    bin_md5=( $(md5sum "$bin") )
    if [[ ${src_md5[0]} != ${bin_md5[0]} ]]; then
        cp -a "$src" "$bin.new"
        chmod u+rx "$bin.new"
        mv -f "$bin.new" "$bin"
        exit 22
    fi
fi

if [[ $vbox_version ]]; then
    # If the guest was updated, it will exit true, otherwise false. There
    # may be a problem with updating the guest so any non-zero exit is like
    # a non-update. Only reasonable test is that we were successful.
    if sudo bash -c "vbox_version='$vbox_version' '$src_dir/vagrant-guest-update.sh'"; then
        exit 33
    fi
fi

pyenv activate radtrack
#TODO(robnagler) test that it is a synced folder. Synced folders may fail.
cd ~/RadTrack

if [[ ! $radtrack_test ]]; then
    # This flag is misnamed. It's really "show fewer tabs"
    radtrack --beta-test < /dev/null
elif DISPLAY= radtrack 2>&1 | grep -s -q 'cannot connect.*X'; then
    exit 0
else
    DISPLAY= radtrack
    exit 99
fi