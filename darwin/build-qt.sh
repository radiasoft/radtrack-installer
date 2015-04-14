#!/bin/bash
if [[ ! $VIRTUAL_ENV ]]; then
    echo 'You must have a pyenv activated.' 1>&2
    exit 1
fi
set -e
tmp=/var/tmp/$USER$$
mkdir "$tmp"
cd "$tmp"
curl -s -L -O http://download.qt.io/official_releases/qt/4.8/4.8.6/qt-everywhere-opensource-src-4.8.6.tar.gz
tar xzf qt-everywhere-opensource-src-4.8.6.tar.gz
rm qt-everywhere-opensource-src-4.8.6.tar.gz
cd qt-everywhere-opensource-src-4.8.6
./configure -opensource -confirm-license -prefix "$VIRTUAL_ENV" -prefix-install -nomake 'tests examples demos docs translations' -no-multimedia -no-webkit -no-javascript-jit -no-phonon -no-xmlpatterns -system-sqlite -no-script -no-svg -no-scripttools -no-qt3support
gmake
gmake install
