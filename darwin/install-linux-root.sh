#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Setup root user
#
set -e
export HOME=/root
cp -a /etc/skel/.??* /root

if [[ -f /.dockerinit ]]; then
    cat > /.bashrc << 'EOF'
export HOME=/root
cd $HOME
. /root/.bash_profile
EOF
fi

curl -s -L https://raw.githubusercontent.com/biviosoftware/home-env/master/install.sh | bash
