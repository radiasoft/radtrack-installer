#!/bin/bash
set -e
umask 022
mkdir /cfg
cp /vagrant/* /cfg
bash /cfg/install-linux.sh
