#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e
qmake=/usr/lib64/qt4/bin/qmake

curl -s -L https://raw.githubusercontent.com/biviosoftware/home-env/master/install.sh | bash
. ~/.bashrc
bivio_pyenv_2

# pybivio
cd ~/src/biviosoftware
git clone -q https://github.com/biviosoftware/pybivio
cd pybivio
pybivio=$(pwd)

# radtrack pyenv
mkdir -p ~/src/radiasoft
cd ~/src/radiasoft
git clone -q https://github.com/radiasoft/radtrack
cd radtrack
bivio_pyenv_local
pyenv activate radtrack
radtrack=$(pwd)
cd $pybivio
python setup.py develop

# Install sip and Qt4
url_base=https://depot.radiasoft.org/foss
tmp=/var/tmp/$USER$$
mkdir $tmp
cd $tmp
base=sip-4.16.6
curl -s -L $url_base/$base.tar.gz | tar xzf -
cd $base
python configure.py --incdir="$VIRTUAL_ENV/include"
make
make install
cd ..
rm -rf $base
base=PyQt-x11-gpl-4.11.3
curl -s -L $url_base/$base.tar.gz | tar xzf -
cd $base
python configure.py --confirm-license -q "$qmake"
make
make install
cd
rm -rf $tmp

# RadTrack install
cd $radtrack
rm -f radtrack/dcp/sdds*
cp install/fedora/sdds* $(python -c 'from distutils.sysconfig import get_python_lib as x; print x()')
