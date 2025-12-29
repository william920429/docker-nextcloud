#!/usr/bin/env bash
set -eu

if [ "$1" == "/usr/bin/supervisord" ] && [ "$EUID" -eq "0" ]; then
    # Run /entrypoint.sh logic
    export NEXTCLOUD_UPDATE=1

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
    echo "This container will run with PUID=${PUID}, PGID=${PGID}"

    for dir in /var/www/html /var/www/log /var/www/cache; do
        echo "Checking permissions for ${dir}..."
        find "${dir}" ! -user www-data -or ! -group www-data \
            -exec chown www-data:www-data {} \;
    done
    echo "All things prepared."
fi

exec /entrypoint.sh "$@"
