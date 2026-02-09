#!/usr/bin/env bash
set -eu

exec_as(){
    exec setpriv --reuid "${PUID}" --regid "${PGID}" --clear-groups -- "$@"
}

ENV_OK=1
_check_env () {
    KEY="$1"
    VALUE="$(printenv $1)"
    if [ -z "${VALUE}" ]; then
        echo "${KEY} not set"
        ENV_OK=0
    else
        echo "${KEY}=\"${VALUE}\""
    fi
}

check_env() {
    # Check environment variables
    echo "Checking environment variables..."
    export PUID=${PUID:-33}
    export PGID=${PGID:-33}
    _check_env PUID
    _check_env PGID
    _check_env NEXTCLOUD_ADMIN_USER
    _check_env NEXTCLOUD_ADMIN_PASSWORD
    _check_env NEXTCLOUD_HOST
    _check_env POSTGRES_DB
    _check_env POSTGRES_USER
    _check_env POSTGRES_PASSWORD
    _check_env POSTGRES_HOST
    _check_env REDIS_HOST
    _check_env OVERWRITECLIURL
    _check_env NOTIFYPUSH_HOST

    if [ "${ENV_OK}" -eq "0" ]; then
        echo "Some environment variables not set!"
        exit 1
    fi
}

setup_user(){
    # Change www-data:www-data to ${PUID}:${PGID}
    [ "$(id -g www-data)" -ne "${PGID}" ] && groupmod www-data -o -g "${PGID}" || true
    [ "$(id -u www-data)" -ne "${PUID}" ] && usermod  www-data -o -u "${PUID}" || true
    rm -f /etc/group- /etc/passwd- /etc/.pwd.lock

    # Make VA-API accessible by www-data
    if [ -c "/dev/dri/renderD128" ]; then
        chgrp www-data /dev/dri/renderD128
    fi

    # Make TTY accessible by www-data
    if [ -c "/dev/stdout" ]; then
        chgrp www-data /dev/stdout
    fi
}

fix_permission(){
    for dir in /var/www/html /var/www/cache; do
        echo "Checking permissions for ${dir}..."
        find "${dir}" -path "*/.snapshots" -prune -or \
            \( ! -user www-data -or ! -group www-data \) \
            -exec chown --no-dereference www-data:www-data {} \; \
            -print
    done
}

setup_notifypush(){
    # Install notify_push
    rsync -a --delete --chown www-data:www-data \
        /usr/src/nextcloud/apps/notify_push/ \
        /var/www/html/apps/notify_push/
    occ app:enable notify_push

    # Config manually in case reverse proxy not ready
    if [ "$(occ config:app:get notify_push base_endpoint)" != "${OVERWRITECLIURL}/push" ]; then
        # Random value [0, 2**30-1]
        occ config:app:set notify_push cookie --value "$(($RANDOM*2**15+$RANDOM))"
        occ config:app:set notify_push base_endpoint --value "${OVERWRITECLIURL}/push"
    fi
}

wait_nextcloud(){
    local max_retries=10
    local try=0
    until  [ "$try" -gt "$max_retries" ] || nc -z "${NEXTCLOUD_HOST}" 80
    do
        echo "waiting for nextcloud ready..."
        try=$((try+1))
        sleep 10s
    done
    if [ "$try" -gt "$max_retries" ]; then
        echo "nextcloud seems not running, exiting..."
        exit 1
    fi
}

if [ "$EUID" -eq "0" ]; then
    case "$(basename "$1")" in
        apache2-foreground)
            check_env
            setup_user
            fix_permission
            # Run /entrypoint.sh logic (install/upgrade/...)
            export NEXTCLOUD_UPDATE=1
            export NEXTCLOUD_INIT_HTACCESS=1
            /entrypoint.sh true
            setup_notifypush
            echo Starting: "$@"
            exec "$@"
        ;;
        supercronic)
            check_env
            setup_user
            wait_nextcloud
            echo Starting: "$@"
            exec_as "$@"
        ;;
        notify_push)
            setup_user
            wait_nextcloud
            echo Starting: "$@"
            exec_as "$@"
        ;;
    esac
fi

exec "$@"
