#!/bin/bash
IMAGE=radiasoft/radtrack
docker rmi $IMAGE
docker build --rm=true --tag=$IMAGE .
