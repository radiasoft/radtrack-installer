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
for f in radtrack-installer radtrack SRW shadow3; do
    git clone --depth 1 -q "${BIVIO_GIT_SERVER-https://github.com}/radiasoft/$f.git"
done

# TODO(robnagler) SDDS install from RPM(?)
install -m 0644 "$build_conf"/sdds* $(python -c 'from distutils.sysconfig import get_python_lib as x; print x()')

(
    cd SRW
    # dependency
    MPICC=/usr/lib64/openmpi/bin/mpicc pip install mpi4py
    make
    make install
)
assert_subshell

(
    cd shadow3
    make
    make libstatic
    python setup.py install
)
assert_subshell

(
    cd radtrack
    # Build radtrack
    python setup.py develop
)
assert_subshell

cp -f "$build_conf"/vagrant-radtrack.sh ~/bin/vagrant-radtrack
chmod +x ~/bin/vagrant-radtrack
