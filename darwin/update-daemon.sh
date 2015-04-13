#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# RadTrack updater. Runs via plist
#
set -e
export install_home=$(dirname $(dirname "$0"))
export install_update_conf=$install_home/etc/update.conf
. "$install_update_conf"
export install_update=1
curl -L -s "$install_url/setup.sh" | bash
