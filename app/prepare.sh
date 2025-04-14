#!/bin/bash
set -eu

# Make VA-API accessible by group www-data
if [[ ! -f "/dev-dri-group-was-added" ]] && [[ -c "/dev/dri/renderD128" ]]; then
    # From https://memories.gallery/hw-transcoding/#docker-installations
    GID="$(stat -c "%g" /dev/dri/renderD128)"
    groupadd -g "$GID" render2 || true # sometimes this is needed
    GROUP="$(getent group "$GID" | cut -d: -f1)"
    usermod -aG "$GROUP" www-data
    touch "/dev-dri-group-was-added"
fi

# Change www-data:www-data to ${PUID}:${PGID}
[[ "$(id -u www-data)" -ne "${PUID}" ]] && usermod  -u "${PUID}" www-data
[[ "$(id -g www-data)" -ne "${PGID}" ]] && groupmod -g "${PGID}" www-data
echo "This container will run with PUID=${PUID}, PGID=${PGID}"

# Setup cron
# CRON_NEXTCLOUD="*/5 * * * * php -f /var/www/html/cron.php"
# is already included in Dockerfile.
if [[ ! -f "/cron-was-added" ]]; then
    {
        for var in "${!CRON_@}"; do
            declare -n ref=$var
            echo "$ref"
        done
    } > /var/spool/cron/crontabs/www-data
    touch "/cron-was-added"
fi

exec "$@"
