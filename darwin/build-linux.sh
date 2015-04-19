#!/bin/bash
set -e
umask 022

set -x

. /cfg/build-env.sh

# Need swap, because scipy build fails otherwise. Allow X11Forwarding
if [[ $(VBoxControl --version 2>/dev/null) ]]; then
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
# Debugging: You don't have to run update to debug so comment this line:
yum --assumeyes --exclude='filesystem*' update
# Debugging: You can subtitute "install" with "debug" below:
yum --assumeyes install $(cat /cfg/yum-install.list)

url_base=https://depot.radiasoft.org/foss
rpm -U "$url_base/elegant-fedora.rpm"
rpm -U "$url_base/SDDSToolKit-fedora.rpm"

# Debugging: Uncomment this:
# exit
#
# Exitting here will get a container which you can then use this to debug further:
# docker run -i -t -v "$(pwd)":/vagrant -h docker radiasoft/radtrack /bin/bash -l
#

. /cfg/build-user-root.sh

rm -f /etc/localtime
ln -s /usr/share/zoneinfo/UCT /etc/localtime

id -u vagrant &>/dev/null || useradd --create-home vagrant
chmod -R a+rX /cfg

# Debugging: Uncomment this:
# exit
#
# If you want to retry building vagrant, you start docker (above) and then repeat:
# userdel -r vagrant; useradd -m vagrant; su - vagrant -c 'bash -x /build-user-vagrant.sh'

su --login vagrant -c 'bash /cfg/build-user-vagrant.sh'
