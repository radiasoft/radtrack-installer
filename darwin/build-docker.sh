#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Sets up the environment to run Docker
#

set -e

# Docker's hardwired container network
build_container_net=172.17.42
. ./build-setup.sh

IMAGE=radiasoft/radtrack
if docker images | grep -s -q $IMAGE; then
    docker rmi $IMAGE
fi

rm -f Dockerfile
cat > Dockerfile <<'EOF'
FROM fedora:21
MAINTAINER RadTrack <docker@radtrack.org>
ADD . /cfg
RUN sh /cfg/build-linux.sh
EOF

docker build --rm=true --tag=$IMAGE .
