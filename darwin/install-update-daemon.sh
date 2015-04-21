#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the update daemon
#
install_msg 'Installing automatic updater...'
plist=/Library/LaunchDaemons/org.radtrack.update.plist
launchctl unload "$plist" &> /dev/null || true

plist_base=$(basename "$plist")
install_get_file "$plist_base"

prog=$(perl -n -e 'm{>(/.*/update-daemon)<} && print($1)' "$plist_base")
if [[ ! $prog ]]; then
    install_err "Unable to parse $plist_base"
fi
base=$(dirname "$(dirname "$prog")")

#Note: keep locations in sync with update-daemon.sh
update_conf=$base/etc/update.conf
echo "export install_update_conf='$update_conf'" >> $install_env_file
setup_sh=$base/lib/setup.sh
for f in "$update_conf" "$setup_sh"; do
    install_mkdir "$(dirname "$f")"
    cp -f "$(basename "$f")" "$f"
done

install_get_file update-daemon.sh
mv -f update-daemon.sh "$prog"
chmod +x "$prog"

mv -f "$plist_base" "$plist"
launchctl load "$plist"
