ARG NEXTCLOUD_VERSION="32"
ARG NOTIFYPUSH_VERSION="1.3.0"
ARG SUPERCRONIC_VERSION="0.2.42"
ARG TARGETARCH

FROM nextcloud:${NEXTCLOUD_VERSION:+${NEXTCLOUD_VERSION}-}apache
# Install dependencies
# intel-media-va-driver-non-free: for intel gpu
# mesa-va-drivers: for amd gpu and nouveau
# ffmpeg: for video preview and memories video stream
# iproute2: for serverinfo app
# netcat-openbsd: for healthcheck and prepare.sh
RUN set -eux; \
    . /etc/os-release; \
    echo "deb http://ftp.debian.org/debian ${VERSION_CODENAME} non-free non-free-firmware" >> \
       /etc/apt/sources.list.d/intel-graphics.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        intel-media-va-driver-non-free \
        mesa-va-drivers \
        ffmpeg \
        iproute2 \
        netcat-openbsd \
    ; \
    rm -rf /var/lib/apt/lists/*;

# Install notify_push
# Latest releases available at https://github.com/nextcloud-releases/notify_push/releases
ARG NOTIFYPUSH_VERSION
ADD --link --unpack=true \
    https://github.com/nextcloud-releases/notify_push/releases/download/v${NOTIFYPUSH_VERSION}/notify_push-v${NOTIFYPUSH_VERSION}.tar.gz \
    /usr/src/nextcloud/apps/

# Install supercronic
# Latest releases available at https://github.com/aptible/supercronic/releases
ARG SUPERCRONIC_VERSION
ARG TARGETARCH
ADD --link --chmod=755 \
    https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-${TARGETARCH} \
    /usr/local/bin/supercronic

# Setup apache, dir and symlink
RUN set -eux; \
    sed -e '$a ServerName localhost' \
        -i /etc/apache2/apache2.conf; \
    a2enmod proxy proxy_http proxy_wstunnel; \
    sed -e '/<\/VirtualHost>/i \\tProxyPass /push/ws ws://${NOTIFYPUSH_HOST}:7867/ws' \
        -e '/<\/VirtualHost>/i \\tProxyPass /push/ http://${NOTIFYPUSH_HOST}:7867/' \
        -e '/<\/VirtualHost>/i \\tProxyPassReverse /push/ http://${NOTIFYPUSH_HOST}:7867/' \
        -i /etc/apache2/sites-available/000-default.conf; \
    chown root:root /var/www; \
    chmod 755 /var/www; \
    rmdir /var/www/data; \
    mkdir -p /var/www/cache; \
    chown www-data:www-data /var/www/html /var/www/cache; \
    chmod 700 /var/www/html /var/www/cache; \
    ln -s /var/www/html/occ /usr/local/bin/occ; \
    ln -s /usr/src/nextcloud/apps/notify_push/bin/$(arch)/notify_push /usr/local/bin/notify_push;

COPY --link custom.config.php /usr/src/nextcloud/config/
COPY --link --chmod=755 prepare.sh /

ENV APACHE_PID_FILE="/tmp/apache2.pid" \
    XDG_CACHE_HOME="/var/www/cache"

STOPSIGNAL SIGWINCH
ENTRYPOINT ["/prepare.sh"]
CMD ["apache2-foreground"]
