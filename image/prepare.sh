#!/usr/bin/env bash
set -eu

ENV_OK=1
check_env () {
    KEY="$1"
    VALUE="$(printenv $1)"
    if [ -z "${VALUE}" ]; then
        echo "ENV ${KEY} not set"
        ENV_OK=0
    elif [ "${2:-}" == "sensitive" ]; then
        echo "ENV ${KEY}=***REMOVED SENSITIVE VALUE***"
    else
        echo "ENV ${KEY}='${VALUE}'"
    fi
}

prepare() {
    # Check environment variables
    echo "Checking environment variables..."
    export PUID=${PUID:-33}
    export PGID=${PGID:-33}
    check_env PUID
    check_env PGID
    check_env NEXTCLOUD_ADMIN_USER
    check_env NEXTCLOUD_ADMIN_PASSWORD sensitive
    check_env NEXTCLOUD_HOST
    check_env POSTGRES_DB
    check_env POSTGRES_USER
    check_env POSTGRES_PASSWORD sensitive
    check_env POSTGRES_HOST
    check_env REDIS_HOST
    check_env OVERWRITECLIURL
    check_env NOTIFYPUSH_HOST

    if [ "${ENV_OK}" -eq "0" ]; then
        echo "Some environment variables not set!"
        exit 1
    fi

    # Change www-data:www-data to ${PUID}:${PGID}
    groupmod www-data -o -g "${PGID}"
    usermod  www-data -o -u "${PUID}" -d /nonexistent

    # Make VA-API accessible by www-data
    if [ -c "/dev/dri/renderD128" ]; then
        chgrp www-data /dev/dri/renderD128
    fi
}

if [ "$EUID" -eq "0" ]; then
    case "$1" in
        apache2-foreground)
            prepare
            for dir in /var/www/html /var/www/cache; do
                echo "Checking permissions for ${dir}..."
                find "${dir}" ! -user www-data -or ! -group www-data \
                    -exec chown --no-dereference www-data:www-data {} \; \
                    -print
            done
            # Run /entrypoint.sh logic (install/upgrade/...)
            export NEXTCLOUD_UPDATE=1
            export NEXTCLOUD_INIT_HTACCESS=1
            /entrypoint.sh true

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
            echo Starting: "$@"
            exec "$@"
        ;;
        supercronic)
            prepare
            echo Starting: "$@"
            exec /su.py www-data "$@"
        ;;
        notify_push)
            prepare
            export DATABASE_URL=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}/${POSTGRES_DB}
            export DATABASE_PREFIX=oc_
            export REDIS_URL=redis://${REDIS_HOST}
            export NEXTCLOUD_URL=http://${NEXTCLOUD_HOST}
            echo Starting: "$@"
            sleep 5
            exec /su.py www-data "$@"
        ;;
    esac
fi

exec "$@"
