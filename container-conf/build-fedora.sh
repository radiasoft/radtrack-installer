#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e

. "$build_env"

chmod -R a+rX "$build_conf"
su --login vagrant -c "build_env='$build_env' bash '$build_conf/user-vagrant.sh'"
