#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Step 2: Running as root
#
d=$(dirname "${BASH_SOURCE[0]}")
cd "$d"
unset d

. ./env.sh
