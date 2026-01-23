#!/usr/bin/env bash
set -eu

CHECK_INTERVAL=60
PATH="$PATH:/var/www/html/custom_apps/notify_push/bin/$(arch)"

usage() {
    echo "Usage: $0 COMMAND"
    echo "Commands:"
    echo "  install  try to install latest notify_push if not installed"
    echo "  check    check if notify_push updated every ${CHECK_INTERVAL} seconds, restart if required"
    echo "  serve    configure and start notify_push"
    exit 1
}

# Install notify_push
# https://github.com/nextcloud-releases/notify_push/releases
install() {
    if [ -d "/var/www/html/custom_apps/notify_push" ]; then
        echo "$(notify_push --version) already installed."
        return 0
    fi

    echo "Installing notify_push..."
    curl -fsSL https://api.github.com/repos/nextcloud-releases/notify_push/releases/latest \
        | jq --raw-output 'first( .assets[] | select(.name | test("notify_push-v.+\\.tar\\.gz")) | .browser_download_url )' \
        | xargs curl -fsSL -o /tmp/notify_push.tar.gz
    tar -zxf /tmp/notify_push.tar.gz -C /var/www/html/custom_apps/
    rm /tmp/notify_push.tar.gz

    echo "Installed $(notify_push --version)"
}

# check whether notify_push was updated from web
check() {
    local BIN_VER OLD_VER

    OLD_VER="$(notify_push --version)"
    while true; do
        BIN_VER="$(notify_push --version)"
        if [ "${BIN_VER}" != "${OLD_VER}" ]; then
            supervisorctl restart notifypush
            echo "${OLD_VER} -> ${BIN_VER}"
            OLD_VER="${BIN_VER}"
        fi
        sleep ${CHECK_INTERVAL}
    done
}

# start notify_push
serve() {
    install
    occ app:enable notify_push

    # Config manually
    if [ "$(occ config:app:get notify_push base_endpoint)" != "${OVERWRITECLIURL}/push" ]; then
        # Random value [0, 2**30-1]
        occ config:app:set notify_push cookie --value "$(($RANDOM*2**15+$RANDOM))"
        occ config:app:set notify_push base_endpoint --value "${OVERWRITECLIURL}/push"
    fi

    exec notify_push \
        --bind "127.0.0.1" \
        --port "7867" \
        --database-url "postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}/${POSTGRES_DB}" \
        --database-prefix "oc_" \
        --redis-url "redis://${REDIS_HOST}" \
        --nextcloud-url "http://127.0.0.1"
}

if [ "$#" -ne "1" ]; then
    usage
fi

case "$1" in
    install)
        install
        ;;
    check)
        check
        ;;
    serve)
        serve
        ;;
    *)
        usage
        ;;
esac
