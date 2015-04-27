#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e

. "$build_env"

url_base=https://radtrack.radiasoft.org/master/$install_host_os
sudo yum install -y "$url_base/elegant-$build_guest_os.rpm" "$url_base/SDDSToolKit-$build_guest_os.rpm"

su --login vagrant -c "build_env='$build_env' bash '$build_conf/user-vagrant.sh'"
