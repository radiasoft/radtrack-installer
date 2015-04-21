#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e

. /cfg/build-env.sh

build_home_env

# Adds bivio_* commands
. ~/.bashrc

# This line stops a warning from the pyenv installer
bivio_path_insert ~/.pyenv/bin 1
bivio_pyenv_2

# Adds pyenv functions now that pyenv exists
. ~/.bashrc

# RadTrack install
mkdir -p ~/src/radiasoft
cd ~/src/radiasoft
git clone -q ${BIVIO_GIT_SERVER-https://github.com}/radiasoft/radtrack-installer.git
git clone -q ${BIVIO_GIT_SERVER-https://github.com}/radiasoft/radtrack.git
cd radtrack
radtrack_dir=$(pwd)

# local pyenv
bivio_pyenv_local
pyenv activate radtrack

# Install sip and Qt4
build_qt_pkg() {
    local tgz=$1.tar.gz
    shift
    # Put tmp local to user, since for dev, we will just userdel -r vagrant
    # in compile-debug loop.
    local tmp=~/build_qt_pkg
    mkdir "$tmp"
    cd "$tmp"
    curl -s -S -L -O "https://depot.radiasoft.org/foss/$tgz"
    tar xzf "$tgz"
    rm -f "$tgz"
    cd *
    python configure.py "$@"
    make
    make install
    cd -
    rm -rf "$tmp"
}

build_qt_pkg sip --incdir="$VIRTUAL_ENV/include"
build_qt_pkg PyQt4 --confirm-license -q /usr/lib64/qt4/bin/qmake

# SDDS install
cd $radtrack_dir
rm -f radtrack/dcp/sdds*
cp /cfg/sdds* $(python -c 'from distutils.sysconfig import get_python_lib as x; print x()')
