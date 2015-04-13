#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Sets up the environment to run Docker
#
IMAGE=radiasoft/radtrack
docker rmi $IMAGE
docker build --rm=true --tag=$IMAGE .
