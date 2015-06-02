#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e
. "$build_env"
. ~/.bashrc

cp -f "$build_conf"/vagrant-radtrack.sh ~/bin/vagrant-radtrack
chmod +x ~/bin/vagrant-radtrack
