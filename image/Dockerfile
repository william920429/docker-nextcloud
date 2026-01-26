ARG NEXTCLOUD_VERSION
FROM nextcloud:${NEXTCLOUD_VERSION:+${NEXTCLOUD_VERSION}-}apache
# Install dependencies
# intel-media-va-driver-non-free: fot intel gpu
# mesa-va-drivers: for amd gpu and nouveau
# ffmpeg: for video preview and memories video stream
# iproute2: for serverinfo app
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
    ; \
    rm -rf /var/lib/apt/lists/*;

# Install notify_push
# Latest releases available at https://github.com/nextcloud-releases/notify_push/releases
ARG NOTIFYPUSH_VERSION
ADD --unpack=true \
    https://github.com/nextcloud-releases/notify_push/releases/download/v${NOTIFYPUSH_VERSION}/notify_push-v${NOTIFYPUSH_VERSION}.tar.gz \
    /usr/src/nextcloud/apps/

# Install supercronic
# Latest releases available at https://github.com/aptible/supercronic/releases
ARG SUPERCRONIC_VERSION
ADD --chmod=755 \
    https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-amd64 \
    /usr/local/bin/supercronic

# Setup apache
RUN set -eux; \
    sed -e '$a ServerName localhost' \
        -e '$a GracefulShutdownTimeout 3' \
        -i /etc/apache2/apache2.conf; \
    a2enmod proxy proxy_http proxy_wstunnel; \
    sed -e '/<\/VirtualHost>/i \\tProxyPass /push/ws ws://${NOTIFYPUSH_HOST}:7867/ws' \
        -e '/<\/VirtualHost>/i \\tProxyPass /push/ http://${NOTIFYPUSH_HOST}:7867/' \
        -e '/<\/VirtualHost>/i \\tProxyPassReverse /push/ http://${NOTIFYPUSH_HOST}:7867/' \
        -i /etc/apache2/sites-available/000-default.conf;

# Setup dir and symlink
RUN set -eux; \
    chown root:root /var/www; \
    rmdir /var/www/data; \
    mkdir -p --mode 1777 /var/www/cache; \
    chown www-data:www-data /var/www/cache; \
    ln -s /var/www/html/occ /usr/local/bin/occ; \
    ln -s /usr/src/nextcloud/apps/notify_push/bin/$(arch)/notify_push /usr/local/bin/notify_push;

COPY custom.config.php /usr/src/nextcloud/config/
COPY --chmod=755 prepare.sh su.py /

ENV APACHE_PID_FILE="/tmp/apache2.pid" \
    XDG_CACHE_HOME="/var/www/cache"

STOPSIGNAL SIGWINCH
ENTRYPOINT ["/prepare.sh"]
CMD ["apache2-foreground"]
