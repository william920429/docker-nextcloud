#!/usr/bin/env bash
set -eu

ENV_OK=1
check_env () {
    if [ "$#" -eq "0" ]; then
        return 1
    fi

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

if [ "$1" == "/usr/bin/supervisord" ] && [ "$EUID" -eq "0" ]; then
    # Run /entrypoint.sh logic
    export NEXTCLOUD_UPDATE=1
    export NEXTCLOUD_INIT_HTACCESS=1

    # Check environment variables
    echo "Checking environment variables..."
    check_env PUID
    check_env PGID
    check_env NEXTCLOUD_ADMIN_USER
    check_env NEXTCLOUD_ADMIN_PASSWORD sensitive
    check_env POSTGRES_DB
    check_env POSTGRES_USER
    check_env POSTGRES_PASSWORD sensitive
    check_env POSTGRES_HOST
    check_env REDIS_HOST
    check_env OVERWRITECLIURL

    if [ "${ENV_OK}" -eq "0" ]; then
        echo "Some environment variables not set!"
        exit 1
    fi

    # Make VA-API accessible by group www-data
    if [ ! -f "/dev-dri-group-was-added" ] && [ -c "/dev/dri/renderD128" ]; then
        # From https://memories.gallery/hw-transcoding/#docker-installations
        GID="$(stat -c "%g" /dev/dri/renderD128)"
        groupadd -g "$GID" render2 || true # sometimes this is needed
        GROUP="$(getent group "$GID" | cut -d: -f1)"
        usermod -aG "$GROUP" www-data
        touch "/dev-dri-group-was-added"
    fi

    # Change www-data:www-data to ${PUID}:${PGID}
    [ "$(id -u www-data)" -ne "${PUID}" ] && usermod  -o -u "${PUID}" www-data
    [ "$(id -g www-data)" -ne "${PGID}" ] && groupmod -o -g "${PGID}" www-data

    for dir in /var/www/html /var/www/log /var/www/cache; do
        echo "Checking permissions for ${dir}..."
        find "${dir}" ! -user www-data -or ! -group www-data \
            -exec chown --no-dereference www-data:www-data {} \; \
            -print
    done
    echo "All things prepared."
fi

/entrypoint.sh true
/notifypush.sh install
exec "$@"
