#!/bin/bash
#
# setup environment for build
#
rm -f build-env.sh
(
    echo "build_container_type='$build_container_type'"
    # Only for debug mode
    port=$(bivio_git_server -port 2>/dev/null || true)
    if [[ $port ]]; then
        # Docker and vagrant always use .1 for host IP
        url="http://$build_container_net.1:$port"
        echo "export BIVIO_GIT_SERVER='$url'"
        echo "*** DEVELOPMENT MODE: Downloads from $url ***" 1>&2
    fi
    cat <<'EOF'
build_home_env() {
    # Needs to be two lines to catch error on retrieval; bash doesn't complain
    # if an empty file ("false | bash" is true)
    if [[ ! -r /cfg/home-env-install.sh ]]; then
        curl -s -S -L ${BIVIO_GIT_SERVER-https://raw.githubusercontent.com}/biviosoftware/home-env/master/install.sh > /cfg/home-env-install.sh
    fi
    no_perl=1 bash /cfg/home-env-install.sh
}
EOF
) > build-env.sh
