#!/bin/bash
#
# Run RadTrack pulling out latest version, checking guest updates,
# and verifying this program is up to date
#
prog=$0
install_channel=$1
host_version=$2

if ! [[ $install_channel && $host_version ]]; then
    echo "Usage: $(basename $0) install-channel virtualbox-host"
    exit 1
fi

start_dir=$(pwd)
cd "$(dirname "$0")"
bin=$(dirname "$(pwd)")/$(basename "$0")

. ~/.bashrc

set -e
cd ~/src/radiasoft
#TODO(robnagler) remove as soon as vm rebuilt with radtrack-installer pulled out
if [[ ! -d radtrack-installer ]]; then
    gcl radtrack-installer
fi

for f in radtrack radtrack-installer; do
    (
        set -e
        cd "$f"
        git fetch -q
        git checkout -q "tags/$install_channel"
    )
done

src=~/src/radiasoft/radtrack-installer/darwin/vagrant-darwin.sh
src_md5=( $(md5sum "$src") )
bin_md5=( $(md5sum "$bin") )
if [[ ${src_md5[0]} != ${bin_md5[0]} ]]; then
    cp -a "$src" "$bin.new"
    chmod a+rx "$bin.new"
    mv -f "$bin.new" "$bin"
    exit 22
fi

guest_version=$(sudo perl -e 'print((`VBoxControl --version` =~ /([\d\.]+)/)[0])')
if [[ $host_version != $guest_version ]]; then
    echo 'Updating virtual machine... (may take ten minutes)'
    # Returns false even when it succeeds, if the reload fails (next),
    # then the guest additions didn't get added right (or something else
    # is wrong)
    sudo bash ~/src/radiasoft/radtrack-installer/darwin/vagrant-guest-update.sh "$host_version"
    exit 33
fi

pyenv activate radtrack
# Invokes the radtrack shim
options=
if [[ $install_channel =~ develop|master|alpha|beta ]]; then
    options=--beta-test
fi
radtrack $options < /dev/null
