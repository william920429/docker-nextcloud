ARG NEXTCLOUD_MAJOR=stable
FROM nextcloud:${NEXTCLOUD_MAJOR}-apache
# Install dependencies
# intel gpu: intel-media-va-driver-non-free
# amd gpu and nouveau: mesa-va-drivers
RUN set -eux; \
    . /etc/os-release; \
    echo "deb http://ftp.debian.org/debian ${VERSION_CODENAME} non-free non-free-firmware" >> \
       /etc/apt/sources.list.d/intel-graphics.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        intel-media-va-driver-non-free \
        mesa-va-drivers \
        ffmpeg \
        supervisor \
        jq \
        iproute2 \
    ; \
    rm -rf /var/lib/apt/lists/*;

# Install supercronic
# Latest releases available at https://github.com/aptible/supercronic/releases
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.41/supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=f70ad28d0d739a96dc9e2087ae370c257e79b8d7 \
    SUPERCRONIC=supercronic-linux-amd64

RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# Setup apache
RUN set -eux; \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf; \
    a2enmod proxy proxy_http proxy_wstunnel; \
    sed -i '/<\/VirtualHost>/i \\n\tProxyPass /push/ws ws://127.0.0.1:7867/ws\n\tProxyPass /push/ http://127.0.0.1:7867/\n\tProxyPassReverse /push/ http://127.0.0.1:7867/' \
        /etc/apache2/sites-available/000-default.conf

# Setup dir
RUN set -eux; \
    mkdir -p --mode 1777 /var/www/log /var/www/cache; \
    chown www-data:www-data /var/www/log /var/www/cache;

ENV APACHE_PID_FILE="/tmp/apache2.pid"
ENV XDG_CACHE_HOME="/var/www/cache"
ENV PATH="$PATH:/var/www/html"

COPY custom.config.php /usr/src/nextcloud/config/
COPY --chmod=755 prepare.sh notifypush.sh /
COPY supervisord.conf /etc/supervisor/supervisord.conf

# www-data is 33 on debian
ENV PUID="33" PGID="33"

STOPSIGNAL SIGTERM
ENTRYPOINT ["/prepare.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
