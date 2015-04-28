#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Create $install_tmp, verifying no other installer/updater is running
#
set -e

export install_tmp=/var/tmp/$install_bundle_name-$install_user-$$

# Define before creating the directory in case of a strange error
# defining this function. The trap has to be set after we have the
# directory.
install_tmp_delete() {
    set +e
    trap - EXIT
    # Go to a dir where a removal bug won't be a problem
    cd /tmp
    rm -rf "$install_tmp"
}

mkdir "$install_tmp"
trap install_tmp_delete EXIT
cd "$install_tmp"
export TMPDIR="$install_tmp"

curl -f -L -s -S "$install_version_url/install.tar.gz" | tar xzf -

. ./install-lock.sh
. ./install-functions.sh
. ./install-darwin-pkg.sh
. ./install-update-daemon.sh

# Last step, because run as the user. The recursive chown could allow
# a local privilege escalation attack, since we return as root after running
# as the user, and run files in this directory. Don't want to chmod,
# because that exposes to more users. At this point, we know the $install_user
# has sudo privs. Other users may not have, and would create a potential
# exploit to be writable by world.
# Safety precaution: don't use "." in the chown. Only give absolute name.
chown -R "$install_user" "$install_tmp" "$install_log_file"
install_log sudo -E -u "$install_user" bash -e "$install_tmp/install-user.sh"

# No more executing from this directory
install_log true Done: install.sh