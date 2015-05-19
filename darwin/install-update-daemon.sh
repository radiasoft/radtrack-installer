#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the update daemon
#
install_msg 'Installing automatic updater...'

install_log  'test'

install_update_vars

prog=$install_update_root/bin/update-daemon
libexec=$install_update_root/libexec
install_lock_sh=$libexec/install-lock.sh
install_functions_sh=$libexec/install-functions.sh
install_init_sh=$libexec/install-init.sh

# Randomize the StartInterval to avoid witching hours: 1100 - 1300 seconds
start_interval=$(( $RANDOM % 200 + 1100 ))
cat <<EOF > "$(basename "$install_update_plist")"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$install_update_label</string>
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

cat > "$(basename "$install_update_conf")" <<EOF
export install_update=1

export install_functions_sh='$install_functions_sh'
export install_host_id='$install_host_id'
export install_user='$install_user'
export install_user_full_name='$install_user_full_name'
export install_user_id='$install_user_id'

. '$install_init_sh'
EOF

for f in "$install_update_conf" "$install_lock_sh" "$install_functions_sh" "$install_init_sh" "$prog" "$install_update_plist"; do
    b=$(basename "$f")
    if [[ $f == $prog ]]; then
        install_template "$b.sh" "$b"
        chmod u+x "$b"
    fi
    install_mkdir "$(dirname "$f")"
    # Need a copy so copy to a tmp and then rename so cp
    # doesn't overwrite existing script (if it happens to be running)
    cp -a -f "$b" "$f.new"
    mv -f "$f.new" "$f"
done

# Reload
install_exec launchctl unload "$install_update_plist" || true
install_exec launchctl load "$install_update_plist"
