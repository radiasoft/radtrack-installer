#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e

. "$build_env"

. ~/.bashrc

# RadTrack install
mkdir -p ~/src/radiasoft
cd ~/src/radiasoft
pyenv activate src
git clone -q ${BIVIO_GIT_SERVER-https://github.com}/radiasoft/radtrack-installer.git
git clone -q ${BIVIO_GIT_SERVER-https://github.com}/radiasoft/radtrack.git

cd radtrack

# SDDS install
rm -f radtrack/dcp/sdds*
cp /cfg/sdds* $(python -c 'from distutils.sysconfig import get_python_lib as x; print x()')

# Build radtrack
python setup.py develop

mkdir ~/bin
cp /cfg/vagrant-radtrack.sh ~/bin/vagrant-radtrack
chmod +x ~/bin/vagrant-radtrack
