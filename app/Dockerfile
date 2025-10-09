# Cache files
FROM scratch AS filecache

ARG DLIB_VERSION=v20.0
ARG PDLIB_VERSION=v1.1.0
ARG PUSH_VERSION=v1.2.0

ADD https://github.com/davisking/dlib.git#${DLIB_VERSION}:dlib /dlib
ADD https://github.com/goodspb/pdlib.git#${PDLIB_VERSION}      /pdlib
ADD https://github.com/nextcloud-releases/notify_push/releases/download/${PUSH_VERSION}/notify_push-${PUSH_VERSION}.tar.gz \
    /notify_push.tar.gz

FROM nextcloud:31-apache
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
RUN --mount=from=filecache,source=/,destination=/mnt,rw \
    set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        cmake \
        libx11-dev \
        libopenblas-dev \
        liblapack-dev \
    ; \
    \
    mkdir -p /mnt/dlib/build; \
    cd /mnt/dlib/build; \
    cmake .. -DBUILD_SHARED_LIBS=ON -DUSE_AVX_INSTRUCTIONS=ON; \
    make -j $(nproc); \
    make install; \
    \
    cd /mnt/pdlib; \
    phpize; \
    ./configure CXXFLAGS="-O2 -mavx2"; \
    make -j $(nproc); \
    make install; \
    echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini; \
    \
    grep -v "libdlib.so" /mnt/dlib/build/install_manifest.txt \
        | xargs -rt rm -rf; \
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
RUN --mount=from=filecache,source=/,destination=/mnt,rw \
    tar -zxf /mnt/notify_push.tar.gz -C /usr/src/nextcloud/custom_apps/;

# Alter apache
RUN set -eux; \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf; \
    a2enmod proxy proxy_http proxy_wstunnel; \
    sed -i '/<\/VirtualHost>/i \\n\tProxyPass /push/ws ws://127.0.0.1:7867/ws\n\tProxyPass /push/ http://127.0.0.1:7867/\n\tProxyPassReverse /push/ http://127.0.0.1:7867/' \
        /etc/apache2/sites-available/000-default.conf

RUN set -eux; \
    chmod 1777 /var/www/data

COPY config/*config.php /usr/src/nextcloud/config/
COPY prepare.sh notifypush.sh supervisord.conf /

# www-data is 33 on debian
ENV PUID=33 PGID=33 
ENV CRON_NEXTCLOUD="*/5 * * * * php -f /var/www/html/cron.php"
ENV NEXTCLOUD_DATA_DIR=/var/www/data

VOLUME [ "/var/www/data" ]

STOPSIGNAL SIGTERM
ENTRYPOINT ["/prepare.sh", "/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
