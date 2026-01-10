#!/usr/bin/env bash
set -eu

CHECK_INTERVAL=60
PUSH_DIR="/var/www/html/custom_apps/notify_push/bin/$(arch)"
PATH="$PATH:$PUSH_DIR"

log() {
    echo "notifypush.sh:" "$@"
}

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
        log "notify_push already installed."
        return 0
    fi

    echo "Installing notify_push..."
    curl -fsSL https://api.github.com/repos/nextcloud-releases/notify_push/releases/latest \
        | jq --raw-output 'first( .assets[] | select(.name | test("notify_push-v.+\\.tar\\.gz")) | .browser_download_url )' \
        | xargs curl -fsSL -o /tmp/notify_push.tar.gz
    tar -zxf /tmp/notify_push.tar.gz -C /var/www/html/custom_apps/
    rm /tmp/notify_push.tar.gz

    log "Installed $(notify_push --version)"
}

# check whether notify_push was updated from web
check() {
    local BIN_VER OLD_VER

    OLD_VER="$(notify_push --version)"
    while true; do
        BIN_VER="$(notify_push --version)"
        if [ "${BIN_VER}" != "${OLD_VER}" ]; then
            supervisorctl restart notifypush
            log "${OLD_VER} -> ${BIN_VER}"
            OLD_VER="${BIN_VER}"
        fi
        sleep ${CHECK_INTERVAL}
    done
}

# start notify_push
serve() {
    if [ ! -f "${PUSH_DIR}/notify_push" ]; then
        log "notify_push binary not found."
        return 1
    fi
    if [ -z "$(occ config:system:get redis host)" ]; then
        log "Redis seems not configured."
        return 1
    fi
    URL="$(occ config:system:get overwrite.cli.url)"
    if [ -z "$URL" ]; then
        log "overwrite.cli.url not configured."
        return 1
    fi
    occ app:enable notify_push

    # Config manually
    if [ "$(occ config:app:get notify_push base_endpoint)" != "$URL/push" ]; then
        # Random value [0, 2**30-1]
        occ config:app:set notify_push cookie --value "$(($RANDOM*2**15+$RANDOM))"
        occ config:app:set notify_push base_endpoint --value "$URL/push"
    fi

    exec notify_push \
        --bind "127.0.0.1" \
        --nextcloud-url "http://127.0.0.1" \
        /var/www/html/config/config.php
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
