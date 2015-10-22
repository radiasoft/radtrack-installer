#!/bin/bash

export install_bundle_display_name='RadTrack'
export install_bundle_name='org.radtrack'
export install_channel='alpha'
export install_channel_url='https://update.radtrack.us/org.radtrack/darwin/x86_64/alpha'
export install_clients_url='https://update.radtrack.us/clients'
export install_curl='curl -f -L -s -S --retry 3'
export install_install_log_file='/var/log/org.radtrack.install.log'
export install_os_machine='darwin/x86_64'
export install_panic_url='https://panic.radtrack.us/errors'
export install_repo='https://update.radtrack.us'
export install_support='support@radtrack.org'
export install_update_conf='/opt/org.radtrack/etc/update.conf'
export install_update_log_file='/var/log/org.radtrack.update.log'
export install_update_root='/opt/org.radtrack'
export install_version='20150624.000750'
export install_version_url='https://update.radtrack.us/org.radtrack/darwin/x86_64/20150624.000750'

. "$install_functions_sh"

if [[ $install_host_id != {{ special_host_id }} ]]; then
    install_msg 'No updates'
    exit 0
fi

install_update_done() {
    curl -T - -L -s "$install_repo/clients/$(date -u +%Y%m%d%H%M%S)-$RANDOM-$install_user-$install_host_id" <<EOF
$0 $(date -u)

################################################################
# $install_update_log_file

$(cat $install_update_log_file 2>&1)
EOF
}

cat /dev/null > $install_update_log_file
install_exec su "$install_user" -c 'bash -e' <<EOF
cd ~/'Library/Application Support/org.radtrack/vagrant'
./bivio_vagrant_ssh 'cd src/radiasoft/pykern; git pull; cd ../radtrack; git pull' < /dev/null
EOF

install_update_done
