#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Sets up the environment to run Docker
#

set -e

. ./setup-build.sh

IMAGE=radiasoft/radtrack
if docker images | grep -s -q $IMAGE; then
    docker rmi $IMAGE
fi
docker build --rm=true --tag=$IMAGE .
