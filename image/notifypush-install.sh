#!/usr/bin/env bash
set -eu
# Install notify_push
# https://github.com/nextcloud-releases/notify_push/releases

PUSH_VERSION="1.2.1"

if [ -d "/var/www/html/custom_apps/notify_push" ]; then
    echo "notify_push already installed, exiting..."
    exit 0
fi

echo "Installing notify_push..."

curl -fsSL -o /tmp/notify_push.tar.gz \
    https://github.com/nextcloud-releases/notify_push/releases/download/v${PUSH_VERSION}/notify_push-v${PUSH_VERSION}.tar.gz

tar -zxf /tmp/notify_push.tar.gz -C /var/www/html/custom_apps/
rm /tmp/notify_push.tar.gz

echo "Installed notify_push v${PUSH_VERSION}"

exit 0
