#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the update daemon
#
d=$(dirname "$install_update_conf")
plist=/Library/LaunchDaemons/org.radtrack.update.plist
launchctl unload "$plist" &> /dev/null || true
install_mkdir "$d"
# Still need to reference local copy so don't mv
cp -f $(basename "$install_update_conf") $install_update_conf

install_get_file update-daemon.sh
install_mkdir "$install_home/bin"
chmod +x update-daemon.sh
# Note: keep in sync with org.radtrack.update.plist
mv -f update-daemon.sh "$install_home/bin/update-daemon"

install_get_file org.radtrack.update.plist
mv -f org.radtrack.update.plist /Library/LaunchDaemons
launchctl load "$plist"
