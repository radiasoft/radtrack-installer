#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Run inside the VM as root. Sets up the environment for install-linux.sh
#
set -e
umask 022
mkdir /cfg
cp /vagrant/* /cfg
bash /cfg/install-linux.sh
