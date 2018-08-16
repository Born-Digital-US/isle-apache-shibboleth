FROM ubuntu:bionic as isle-apache

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="ISLE Apache Image" \
      org.label-schema.description="Primary Islandora Image." \
      org.label-schema.url="https://islandora-collaboration-group.github.io" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/Islandora-Collaboration-Group/isle-apache" \
      org.label-schema.vendor="Islandora Collaboration Group (ICG) - islandora-consortium-group@googlegroups.com" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0" \
      traefik.enable="true" \
      traefik.port="80" \
      traefik.backend="isle-apache"


## S6-Overlay @see: https://github.com/just-containers/s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.4.0/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C / && \
    rm /tmp/s6-overlay-amd64.tar.gz

ENV INITRD=no \
    ISLANDORA_UID=${ISLANDORA_UID:-1000} \
    ENABLE_XDEBUG=${ENABLE_XDEBUG:-false} \
    PULL_ISLE_BUILD_TOOLS=${PULL_ISLE_BUILD_TOOLS:-true}

## General Dependencies
RUN GEN_DEP_PACKS="software-properties-common \
    language-pack-en-base \
    tmpreaper \
    dnsutils \
    ca-certificates \
    cron \
    wget \
    curl \
    rsync\
    git \
    xz-utils \
    zip \
    unzip \
    bzip2 \
    openssl \
    openssh-client \
    mysql-client" && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && \
    apt-get install --no-install-recommends -y $GEN_DEP_PACKS && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en

## tmpreaper - cleanup /tmp on the running container
RUN touch /var/log/cron.log && \
    touch /etc/cron.d/tmpreaper-cron && \
    echo "0 */12 * * * root /usr/sbin/tmpreaper -am 4d /tmp >> /var/log/cron.log 2>&1" | tee /etc/cron.d/tmpreaper-cron && \
    chmod 0644 /etc/cron.d/tmpreaper-cron

## JAVA PHASE
## Oracle Java 8, default.
RUN echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 boolean true' | debconf-set-selections && \
    add-apt-repository -y ppa:webupd8team/java && \
    JAVA_PACKAGES="oracle-java8-installer \
    oracle-java8-set-default" && \
    apt-get update && \
    apt-get install --no-install-recommends -y $JAVA_PACKAGES && \
    ## Cleanup phase.
    add-apt-repository --remove -y ppa:webupd8team/java && \
    apt-get purge -y --auto-remove openjdk* && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/oracle-jdk8-installer

ENV JAVA_HOME=/usr/lib/jvm/java-8-oracle \
    JRE_HOME=/usr/lib/jvm/java-8-oracle/jre \
    PATH=$PATH:$HOME/.composer/vendor/bin:/usr/lib/jvm/java-8-oracle/bin:/usr/lib/jvm/java-8-oracle/jre/bin \
    KAKADU_LIBRARY_PATH=/usr/local/lib \
    KAKADU_HOME=/usr/local/bin \
    LD_LIBRARY_PATH=/usr/local/lib \
    COMPOSER_ALLOW_SUPERUSER=1

## Apache, PHP, FFMPEG, and other Islandora Depends.
## Apache && PHP 5.6 from ondrej PPA
## Per @g7morris, ghostscript from repo is OK.
RUN add-apt-repository -y ppa:ondrej/apache2 && \
    add-apt-repository -y ppa:ondrej/php && \
    FFMPEG_PACKS="ffmpeg \
    ffmpeg2theora \
    libavcodec-extra \
    lame \
    ghostscript \
    xpdf \
    poppler-utils" && \
    APACHE_PACKS="apache2 \
    python-mysqldb \
    libxml2-dev \
    libapache2-mod-php5.6 \
    libcurl3-openssl-dev \
    php5.6 \
    php5.6-cli \
    php5.6-json \
    php5.6-common \
    php5.6-readline \
    php-pear \
    php5.6-curl \
    php5.6-mbstring \
    php5.6-xmlrpc \
    php5.6-dev \
    php5.6-gd \
    php5.6-ldap \
    php5.6-xml \
    php5.6-mcrypt \
    php5.6-mysql \
    php5.6-soap \
    php5.6-xsl \
    php5.6-zip \
    php5.6-bcmath \
    php5.6-intl \
    php5.6-imagick \
    php-uploadprogress \
    php-xdebug \
    bibutils \
    libicu-dev \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-fra \
    tesseract-ocr-spa \
    tesseract-ocr-ita \
    tesseract-ocr-por \
    tesseract-ocr-hin \
    tesseract-ocr-deu \
    tesseract-ocr-jpn \
    tesseract-ocr-rus \
    leptonica-progs \
    libleptonica-dev" && \
    apt-get update && \
    apt-get install --no-install-recommends -y $FFMPEG_PACKS $APACHE_PACKS && \
    ## PHP conf  
    phpdismod xdebug && \
    ## memory_limit = -1?
    sed -i 's/memory_limit = .*/memory_limit = '256M'/' /etc/php/5.6/apache2/php.ini && \
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = '2000M'/' /etc/php/5.6/apache2/php.ini && \
    sed -i 's/post_max_size = .*/post_max_size = '2000M'/' /etc/php/5.6/apache2/php.ini && \
    sed -i 's/max_input_time = .*/max_input_time = '-1'/' /etc/php/5.6/apache2/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = '0'/' /etc/php/5.6/apache2/php.ini && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

###
# FFMPEG, ImageMagick, Imagick (php), Adore-Djatoka (Kakadu), and OpenJPG
RUN BUILD_DEPS="build-essential \
    cmake \
    pkg-config \
    libtool" && \
    IMAGEMAGICK_LIBS="libbz2-dev \
    libdjvulibre-dev \
    libexif-dev \
    libgif-dev \
    libjpeg8 \
    libjpeg-dev \
    liblqr-dev \
    libopenexr-dev \
    libopenjp2-7-dev \
    libpng-dev \
    libraw-dev \
    librsvg2-dev \
    libtiff-dev \
    libwmf-dev \
    libwebp-dev \
    libwmf-dev \
    zlib1g-dev" && \
    ## I believe these are unused and actually install by libavcodec-extra.
    IMAGEMAGICK_LIBS_EXTENDED="libfontconfig \
    libfreetype6-dev" && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && \
    apt-get install -y --no-install-recommends -o APT::Get::Install-Automatic=true $BUILD_DEPS && \
    apt-mark auto $BUILD_DEPS software-properties-common && \
    apt-get install -y --no-install-recommends $IMAGEMAGICK_LIBS && \
    ## Adore-Djatoka
    cd /tmp && \
    ## Kakadu libraries from adore-djatoka. (Is this even necessary anymore?)
    wget http://downloads.sourceforge.net/project/djatoka/djatoka/1.1/adore-djatoka-1.1.tar.gz && \
    tar xf adore-djatoka-1.1.tar.gz && \
    cp -rv adore-djatoka-1.1/bin/Linux-x86-64/* /usr/local/bin/ && \
    cp -rv adore-djatoka-1.1/lib/Linux-x86-64/* /usr/local/lib/ && \
    ldconfig && \
    ## OpenJPEG 2000
    cd /tmp && \
    git clone https://github.com/uclouvain/openjpeg && \
    cd openjpeg && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make && \
    make install && \
    ldconfig && \
    ## ImageMagick latest
    cd /tmp && \
    wget https://www.imagemagick.org/download/ImageMagick.tar.gz && \
    tar xf ImageMagick.tar.gz && \
    cd ImageMagick-* && \
    ./configure --enable-hdri --with-quantum-depth=16 --without-x --without-magick-plus-plus --without-perl --with-rsvg && \
    make && \
    make install && \
    ldconfig && \
    ## PHP ImageMagick latest (IMagick)
    cd /tmp && \
    wget http://pecl.php.net/get/imagick && \
    tar xf imagick && \
    cd imagick-* && \
    phpize && \
    ./configure --with-imagick=/usr/local/bin && \
    make && \
    make install && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Let's go!  Finalize all remaining: djatoka, composer, drush, fits.
RUN useradd --comment 'Islandora User' --no-create-home -d /var/www/html --system --uid $ISLANDORA_UID --user-group -s /bin/bash islandora && \
    chown -R islandora:www-data /var/www/html && \
    ## Temporary directory for composer, fits, etc...
    mkdir -p /tmp/build && \
    ## COMPOSER
    wget -O composer-setup.php https://raw.githubusercontent.com/composer/getcomposer.org/2091762d2ebef14c02301f3039c41d08468fb49e/web/installer && \
    php composer-setup.php --filename=composer --install-dir=/usr/local/bin && \
    ## DRUSH 8.x as recommended by @g7morris
    mkdir -p /opt/drush-8.x && \
    cd /opt/drush-8.x && \
    /usr/local/bin/composer init --require=drush/drush:8.* -n && \
    /usr/local/bin/composer config bin-dir /usr/local/bin && \
    /usr/local/bin/composer install && \
    ## FITS
    cd /tmp/build && \
    wget https://projects.iq.harvard.edu/files/fits/files/fits-1.2.0.zip && \
    unzip fits-1.2.0.zip && \
    mv fits-1.2.0 /usr/local/fits && \
    ln -s /usr/local/fits/fits.sh /usr/local/bin/fits && \
    mkdir -p /var/log/fits && \
    chgrp www-data /var/log/fits && \
    chmod 775 /var/log/fits && \
    sed -i 's#log4j.appender.FILE.File = .*#log4j.appender.FILE.File = /var/log/fits/fits.log#' /usr/local/fits/log4j.properties && \
    ## BUILD TOOLS
    mkdir /utility-scripts && \
    cd /utility-scripts && \
    git clone https://github.com/Islandora-Collaboration-Group/isle_drupal_build_tools.git && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY rootfs /

RUN a2dissite 000-default && \
    a2ensite isle_localdomain.conf && \
    a2enmod rewrite deflate headers expires proxy proxy_http proxy_html proxy_connect remoteip xml2enc

VOLUME /var/www/html

EXPOSE 80

ENTRYPOINT ["/init"]