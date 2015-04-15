#!/bin/bash
#
# setup environment for build
#
rm -f dev-env.sh
_url=$(bivio_git_server -url 2>/dev/null)
if [[ $_url ]]; then
    echo "# dynamically created by $0 on $(date)" > dev-env.sh
    echo export "BIVIO_GIT_SERVER='$_url'" > dev-env.sh
    echo "Using local read-only git server at $_url"
fi
unset _url
