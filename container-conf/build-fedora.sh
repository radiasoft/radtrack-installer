#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e

. "$build_env"

#NEED a channel: https://radtrack.radiasoft.org/depot/foss
url_base=$build_conf
yum install -y "$build_conf"/*.rpm

chmod -R a+rX "$build_conf"
su --login vagrant -c "build_env='$build_env' bash '$build_conf/user-vagrant.sh'"
