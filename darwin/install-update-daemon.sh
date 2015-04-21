#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the update daemon
#
install_msg 'Installing automatic updater...'
base_domain=org.radiasoft
dest_dir="/opt/$base_domain"
label=$base_domain.update
plist_base=$label.plist
plist=/Library/LaunchDaemons/$plist_base

prog=$dest_dir/bin/update-daemon
# Randomize the StartInterval to avoid witching hours: 1100 - 1300 seconds
start_interval=$(perl -e 'print(int(rand()*200+1100))')
label=$(basename "$plist_base" .plist)
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

#Note: keep locations in sync with update-daemon.sh
update_conf=$dest_dir/etc/update.conf
echo "export install_update_conf='$update_conf'" >> "$install_env_file"
setup_sh=$dest_dir/lib/setup.sh
for f in "$update_conf" "$setup_sh" "$prog.sh" "$plist"; do
    b=$(basename "$f")
    if [[ ! -r $b ]]; then
        install_get_file "$b"
    fi
    install_mkdir "$(dirname "$f")"
    if [[ $b == update-daemon.sh ]]; then
        chmod u+rx "$b"
        f=${f%.sh}
    fi
    cp -a -f "$b" "$f.new"
    mv -f "$f.new" "$f"
done

# Reload: why isn't there a reload?
install_log launchctl unload "$plist" || true
install_log launchctl load "$plist"
