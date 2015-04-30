#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the update daemon
#
install_msg 'Installing automatic updater...'

install_log : 'test'

dest_root=/opt/$install_bundle_name
label=$install_bundle_name.update
plist_base=$label.plist
plist=/Library/LaunchDaemons/$plist_base
prog=$dest_root/bin/update-daemon
libexec=$dest_root/libexec
install_lock_sh=$libexec/install-lock.sh
install_functions_sh=$libexec/install-functions.sh

# Randomize the StartInterval to avoid witching hours: 1100 - 1300 seconds
start_interval=$(perl -e 'print(int(rand()*200+1100))')
cat <<EOF > "$plist_base"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$label</string>
    <key>Disabled</key>
    <false/>
    <key>ProgramArguments</key>
    <array>
        <string>$prog</string>
    </array>
    <key>StandardOutPath</key>
    <string>$install_update_log_file</string>
    <key>StandardErrorPath</key>
    <string>$install_update_log_file</string>
    <key>UserName</key>
    <string>root</string>
    <key>StartInterval</key>
    <integer>$start_interval</integer>
</dict>
</plist>
EOF

#Note: keep location in sync with update-daemon
update_conf=$dest_root/etc/update.conf

cat > "$(basename "$update_conf")" <<EOF
export install_channel='$install_channel'
export install_channel_url='$install_channel_url'
export install_curl='$install_curl'
export install_debug='$install_debug'
export install_host_id='$install_host_id'
export install_keep='$install_keep'
export install_update=1
export install_user='$install_user'
export install_version='$install_version'

. '$install_lock_sh'
. '$install_functions_sh'

EOF

for f in "$update_conf" "$install_lock_sh" "$install_functions_sh" "$prog" "$plist"; do
    b=$(basename "$f")
    if [[ $f == $prog ]]; then
        b=$b.sh
        chmod u+rx "$b"
    fi
    install_mkdir "$(dirname "$f")"
    # Need a copy so copy to a tmp and then rename, because
    # doesn't overwrite exciting script (if happens to be running)
    cp -a -f "$b" "$b.new"
    mv -f "$b.new" "$f"
done

# Reload
install_log launchctl unload "$plist" || true
install_log launchctl load "$plist"
