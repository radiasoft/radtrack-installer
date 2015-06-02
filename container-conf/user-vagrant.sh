#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e
. "$build_env"
. ~/.bashrc

# This doesn't seem to do much
cd ~/src/radiasoft/pykern
python setup.py install
cd ../radtrack
python setup.py install
cd
rm -rf src/radiasoft ~/.cache
