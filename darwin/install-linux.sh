#!/bin/bash
set -e
umask 022
cfg=/cfg
chmod -R a+rX /cfg

if /sbin/lsmod | grep -i -s -q vbox; then
    dd if=/dev/zero of=/swap bs=1M count=1024
    mkswap /swap
    chmod 600 /swap
    swapon /swap
    echo '/swap none swap sw 0 0' >> /etc/fstab
    perl -pi -e 's{^(X11Forwarding) no}{$1 yes}' /etc/ssh/sshd_config
    systemctl restart sshd.service
fi

yum --assumeyes update
yum --quiet --assumeyes install $(cat /cfg/yum-install.list)

url_base=https://depot.radiasoft.org/foss
rpm -U $url_base/elegant-27.0.4-1.fedora.21.openmpi.x86_64.rpm
rpm -U $url_base/SDDSToolKit-3.3.1-1.fedora.21.x86_64.rpm

. /cfg/install-linux-root.sh

rm -f /etc/localtime
ln -s /usr/share/zoneinfo/UCT /etc/localtime

exec_user=vagrant
id -u $exec_user &>/dev/null || useradd --create-home $exec_user
su --login $exec_user --command="sh /cfg/install-linux-user.sh"
