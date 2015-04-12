#!/bin/bash
# set -e
# /tmp may be small
export TMP=/var/tmp/$USER$$
# Just in case $TMP gets set by something else
_install_exec_user_tmp=$TMP
_install_exec_user_exit() {
    local e=$?
    rm -rf "$_install_exec_user_tmp"
    exit $e
}
trap _install_exec_user_exit EXIT ERR

set -e
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

# radtrack import
cd $radtrack
python setup.py develop
rm -f radtrack/dcp/sdds*
cp install/fedora/sdds* $(python -c 'from distutils.sysconfig import get_python_lib as x; print x()')

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
cat > ~/.post.bashrc << 'EOF'
py2
EOF
