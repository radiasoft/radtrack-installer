#!/bin/bash
#
# Functions and vars for installer and update-daemon
#

x=$(dirname "${BASH_SOURCE[0]}")
. "$x/install-functions.sh"
. "$x/install-lock.sh"
unset x

if [[ $install_update ]]; then
    export install_mode=update
    export install_log_file=$install_update_log_file
else
    export install_mode=install
    export install_log_file=$install_install_log_file
    cat /dev/null > "$install_log_file"
fi

cat <<EOF >> "$install_log_file"
################################################################

Starting: $0 $@
at $(date)
in $(pwd)

$(env | sort)

EOF
# So can be read by trap in install.sh
chown "$install_user" "$install_log_file"

# May not have an install_tmp, but install_lock must exist
export install_ok=$install_lock/ok
