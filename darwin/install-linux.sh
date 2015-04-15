#!/bin/bash
set -e
umask 022
chmod -R a+rX /cfg

if [[ -r dev.sh ]]; then
    . /cfg/dev-env.sh
fi

# The -e makes easier for development
if [[ ! -e /swap && $(VBoxControl --version 2>/dev/null) ]]; then
    dd if=/dev/zero of=/swap bs=1M count=1024
    mkswap /swap
    chmod 600 /swap
    swapon /swap
    echo '/swap none swap sw 0 0' >> /etc/fstab
    perl -pi -e 's{^(X11Forwarding) no}{$1 yes}' /etc/ssh/sshd_config
    systemctl restart sshd.service
fi

# https://bugzilla.redhat.com/show_bug.cgi?format=multiple&id=1171928
# error: unpacking of archive failed on file /sys: cpio: chmod
# error: filesystem-3.2-28.fc21.x86_64: install failed
##### yum --assumeyes --exclude='filesystem*' update
yum --assumeyes install $(cat /cfg/yum-install.list | grep -v '^#')

url_base=https://depot.radiasoft.org/foss
rpm -U $url_base/elegant-27.0.4-1.fedora.21.openmpi.x86_64.rpm
rpm -U $url_base/SDDSToolKit-3.3.1-1.fedora.21.x86_64.rpm

. /cfg/install-linux-root.sh

rm -f /etc/localtime
ln -s /usr/share/zoneinfo/UCT /etc/localtime

exec_user=vagrant
id -u $exec_user &>/dev/null || useradd --create-home $exec_user
exit
su --login $exec_user --command="sh /cfg/install-linux-user.sh"
