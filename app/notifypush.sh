#!/bin/bash
export PATH=$PATH:/var/www/html

if [[ -z "$(occ config:system:get redis host)" ]]; then
    echo "Redis seems not configured."
    exit 0
fi

if [[ ! -f "/var/www/html/custom_apps/notify_push/bin/x86_64/notify_push" ]]; then
    echo "notify_push binary not found."
    exit 0
fi

URL="$(occ config:system:get overwrite.cli.url)"
if [[ -z "$URL" ]]; then
    echo "overwrite.cli.url not configured."
    exit 0
fi

occ app:enable notify_push

# Config manually
if [[ "$(occ config:app:get notify_push base_endpoint)" != "$URL/push" ]]; then
    # Random value [0, 2**30-1]
    occ config:app:set notify_push cookie --value "$(($RANDOM*2**15+$RANDOM))"
    occ config:app:set notify_push base_endpoint --value "$URL/push"
fi

exec /var/www/html/custom_apps/notify_push/bin/x86_64/notify_push \
        --bind "127.0.0.1" \
        --nextcloud-url "http://127.0.0.1" \
        /var/www/html/config/config.php
