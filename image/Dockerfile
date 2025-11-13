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
        libbz2-dev \
        supervisor \
    ; \
    docker-php-ext-install bz2; \
    apt-get remove -y --autoremove libbz2-dev; \
    rm -rf /var/lib/apt/lists/*;

# Install DLIB and PDLIB
# https://github.com/davisking/dlib
# https://github.com/goodspb/pdlib
ARG DLIB_VERSION
ARG PDLIB_VERSION
RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        cmake \
        libx11-dev \
        libopenblas-dev \
        liblapack-dev \
    ; \
    \
    cd /tmp; \
    curl -fsSL -o dlib.tar.gz https://github.com/davisking/dlib/archive/refs/tags/v${DLIB_VERSION}.tar.gz; \
    tar -zxf dlib.tar.gz; \
    cd dlib-${DLIB_VERSION}/dlib; \
    mkdir build; \
    cd build; \
    cmake .. -DBUILD_SHARED_LIBS=ON -DUSE_AVX_INSTRUCTIONS=ON; \
    make -j $(nproc); \
    make install; \
    \
    cd /tmp; \
    curl -fsSL -o pdlib.tar.gz https://github.com/goodspb/pdlib/archive/refs/tags/v${PDLIB_VERSION}.tar.gz; \
    tar -zxf pdlib.tar.gz; \
    cd pdlib-${PDLIB_VERSION}; \
    phpize; \
    ./configure CXXFLAGS="-O2 -mavx2"; \
    make -j $(nproc); \
    make install; \
    echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini; \
    \
    cd /tmp; \
    cat dlib-${DLIB_VERSION}/dlib/build/install_manifest.txt \
        | grep -v "/usr/local/lib/libdlib.so" \
        | xargs -rt rm -rf; \
    \
    rm -rf dlib.tar.gz dlib-${DLIB_VERSION}; \
    rm -rf pdlib.tar.gz pdlib-${PDLIB_VERSION}; \
    \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual ${savedAptMark}; \
    apt-mark manual libopenblas0-pthread; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
        | sort -u \
        | xargs -r dpkg-query --search \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*;

# Bundle notify_push
# https://github.com/nextcloud-releases/notify_push/releases
ARG PUSH_VERSION
RUN set -eux; \
    cd /tmp; \
    curl -fsSL -o notify_push.tar.gz https://github.com/nextcloud-releases/notify_push/releases/download/v${PUSH_VERSION}/notify_push-v${PUSH_VERSION}.tar.gz; \
    tar -zxf notify_push.tar.gz -C /usr/src/nextcloud/custom_apps/; \
    rm notify_push.tar.gz;

# Install supercronic
# Latest releases available at https://github.com/aptible/supercronic/releases
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.39/supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=c98bbf82c5f648aaac8708c182cc83046fe48423 \
    SUPERCRONIC=supercronic-linux-amd64
RUN set -eux; \
    curl -fsSLO "$SUPERCRONIC_URL"; \
    echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c -; \
    chmod +x "$SUPERCRONIC"; \
    mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}"; \
    ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic;

# Alter apache
RUN set -eux; \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf; \
    a2enmod proxy proxy_http proxy_wstunnel; \
    sed -i '/<\/VirtualHost>/i \\n\tProxyPass /push/ws ws://127.0.0.1:7867/ws\n\tProxyPass /push/ http://127.0.0.1:7867/\n\tProxyPassReverse /push/ http://127.0.0.1:7867/' \
        /etc/apache2/sites-available/000-default.conf

COPY custom.config.php /usr/src/nextcloud/config/
COPY --chmod=755 prepare.sh notifypush.sh /
COPY supervisord.conf /

# www-data is 33 on debian
ENV PUID=33 PGID=33 
ENV CRON_NEXTCLOUD="*/5 * * * * php -f /var/www/html/cron.php"

STOPSIGNAL SIGTERM
ENTRYPOINT ["/prepare.sh", "/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
