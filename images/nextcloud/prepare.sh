#!/usr/bin/env bash
set -eu -o pipefail

ENV_OK=1
_check_env() {
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
    _check_env NGINX_HOST
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

setup_devices() {
    # Make VA-API accessible
    if [ -c "/dev/dri/renderD128" ]; then
        chgrp "${PGID}" /dev/dri/renderD128
    fi

    # Make TTY accessible
    if [ -c "/dev/stdout" ]; then
        chgrp "${PGID}" /dev/stdout
    fi
}

setup_user() {
    sed "s@^www-data:.*@www-data:x:${PUID}:${PGID}:www-data:/var/www:/usr/sbin/nologin@" \
        -i /etc/passwd
    
    sed "s@^www-data:.*@www-data:x:${PGID}:@" \
        -i /etc/group
}

fix_permission() {
    chown "${PUID}:${PGID}" /var/www/html /var/www/cache
    if [ -d /var/www/html/data ]; then
        chown "${PUID}:${PGID}" /var/www/html/data
    fi
}

setup_notifypush() {
    # Install notify_push
    rsync -a --delete --chown "${PUID}:${PGID}" \
        /usr/src/nextcloud/apps/notify_push/ \
        /var/www/html/apps/notify_push/
    occ app:enable notify_push

    # Config manually in case reverse proxy not ready
    if [ "$(occ config:app:get notify_push base_endpoint)" != "${OVERWRITECLIURL}/push" ]; then
        # Random value [0, 2**30-1]
        occ config:app:set notify_push cookie --value "$((RANDOM * 2 ** 15 + RANDOM))"
        occ config:app:set notify_push base_endpoint --value "${OVERWRITECLIURL}/push"
    fi
}

# wait_service app 9000
wait_service() {
    trap 'exit 143;' TERM

    local max_retries=3
    local try=0
    until [ "$try" -gt "$max_retries" ] || nc -z "$1" "$2"; do
        echo "waiting for nextcloud $1:$2 ready..."
        try=$((try + 1))
        sleep 5s &
        wait $!
    done
    if [ "$try" -gt "$max_retries" ]; then
        echo "nextcloud $1:$2 seems not running, exiting..."
        exit 1
    fi
}

nextcloud_entrypoint() {
    # Run /entrypoint.sh logic (install/upgrade/...)
    export NEXTCLOUD_UPDATE=1
    # export NEXTCLOUD_INIT_HTACCESS=1
    touch /usr/local/etc/php/conf.d/redis-session.ini
    chmod 666 /usr/local/etc/php/conf.d/redis-session.ini
    run_as /entrypoint.sh true
    chmod 644 /usr/local/etc/php/conf.d/redis-session.ini
}

if [ "${EUID}" -eq "0" ]; then
    case "$(basename "$1")" in
        apache2-foreground|php-fpm)
            check_env
            setup_devices
            setup_user
            fix_permission
            nextcloud_entrypoint
            setup_notifypush
            echo Starting: "$@"
            exec "$@"
            ;;
        supercronic)
            check_env
            setup_devices
            setup_user
            wait_service "${NEXTCLOUD_HOST}" 9000
            echo Starting: "$@"
            exec run_as "$@"
            ;;
        nginx)
            setup_user
            wait_service "${NEXTCLOUD_HOST}" 9000
            echo Starting: "$@"
            exec "$@"
            ;;
        notify_push)
            wait_service "${NGINX_HOST}" 80
            echo Starting: "$@"
            exec run_as "$@"
            ;;
    esac
fi

exec "$@"
