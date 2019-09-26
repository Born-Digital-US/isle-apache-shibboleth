FROM adoptopenjdk/openjdk8:latest

ENV INITRD=no \
    ISLANDORA_UID=${ISLANDORA_UID:-1000} \
    ENABLE_XDEBUG=${ENABLE_XDEBUG:-false} \
    PULL_ISLE_BUILD_TOOLS=${PULL_ISLE_BUILD_TOOLS:-true} \
    ISLE_BUILD_TOOLS_REPO=${ISLE_BUILD_TOOLS_REPO:-https://github.com/Islandora-Collaboration-Group/isle_drupal_build_tools.git} \
    ISLE_BUILD_TOOLS_BRANCH=${ISLE_BUILD_TOOLS_BRANCH:-master}
    ## @TODO: add GH creds to container for private repo pulls.

## General Dependencies
RUN GEN_DEP_PACKS="software-properties-common \
    language-pack-en-base \
    tmpreaper \
    cron \
    dnsutils \
    wget \
    rsync \
    git \
    unzip \
    tmpreaper \
    libapr1-dev \
    libssl-dev \
    xz-utils \
    zip \
    bzip2 \
    openssl \
    openssh-client \
    mysql-client\
    file" && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && \
    apt-get install --no-install-recommends -y $GEN_DEP_PACKS && \
    ## CONFD
    curl -L -o /usr/local/bin/confd https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64 && \
    chmod +x /usr/local/bin/confd && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## S6-Overlay @see: https://github.com/just-containers/s6-overlay
ENV S6_OVERLAY_VERSION=${S6_OVERLAY_VERSION:-1.22.1.0}
ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C / && \
    rm /tmp/s6-overlay-amd64.tar.gz

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en

## tmpreaper - cleanup /tmp on the running container
RUN touch /var/log/cron.log && \
    touch /etc/cron.d/tmpreaper-cron && \
    echo "0 */12 * * * root /usr/sbin/tmpreaper -am 4d /tmp >> /var/log/cron.log 2>&1" | tee /etc/cron.d/tmpreaper-cron && \
    chmod 0644 /etc/cron.d/tmpreaper-cron

ENV PATH=$PATH:$HOME/.composer/vendor/bin \
    KAKADU_HOME=/usr/local/adore-djatoka-1.1/bin/Linux-x86-64 \
    KAKADU_LIBRARY_PATH=/usr/local/adore-djatoka-1.1/lib/Linux-x86-64 \
    LD_LIBRARY_PATH=/usr/local/adore-djatoka-1.1/lib/Linux-x86-64:/usr/local/lib:$LD_LIBRARY_PATH \
    COMPOSER_ALLOW_SUPERUSER=1

## Apache, PHP, FFMPEG, and other Islandora Depends.
## Apache && PHP 7.1 from ondrej PPA
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
    libapache2-mod-php7.1 \
    libcurl3-openssl-dev \
    php7.1 \
    php7.1-cli \
    php7.1-json \
    php7.1-common \
    php7.1-readline \
    php-pear \
    php7.1-curl \
    php7.1-mbstring \
    php7.1-xmlrpc \
    php7.1-dev \
    php7.1-gd \
    php7.1-ldap \
    php7.1-xml \
    php7.1-mcrypt \
    php7.1-mysql \
    php7.1-soap \
    php7.1-xsl \
    php7.1-zip \
    php7.1-bcmath \
    php7.1-intl \
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
    sed -i 's/memory_limit = .*/memory_limit = '256M'/' /etc/php/7.1/apache2/php.ini && \
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = '2000M'/' /etc/php/7.1/apache2/php.ini && \
    sed -i 's/post_max_size = .*/post_max_size = '2000M'/' /etc/php/7.1/apache2/php.ini && \
    sed -i 's/max_input_time = .*/max_input_time = '-1'/' /etc/php/7.1/apache2/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = '0'/' /etc/php/7.1/apache2/php.ini && \
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
    libltdl-dev \
    zlib1g-dev" && \
    ## I believe these are unused and actually install by libavcodec-extra.
    IMAGEMAGICK_LIBS_EXTENDED="libfontconfig \
    libfreetype6-dev" && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && \
    apt-get install -y --no-install-recommends -o APT::Get::Install-Automatic=true $BUILD_DEPS && \
    # apt-mark auto $BUILD_DEPS software-properties-common && \
    apt-get install -y --no-install-recommends $IMAGEMAGICK_LIBS && \
    ## Adore-Djatoka
    cd /tmp && \
    ## Kakadu libraries from adore-djatoka for JP2 derivatives.
    curl -LO http://downloads.sourceforge.net/project/djatoka/djatoka/1.1/adore-djatoka-1.1.tar.gz && \
    tar -xzf adore-djatoka-1.1.tar.gz -C /usr/local && \
    ln -s /usr/local/adore-djatoka-1.1/bin/Linux-x86-64/kdu_compress /usr/local/bin/kdu_compress && \
    ln -s /usr/local/adore-djatoka-1.1/bin/Linux-x86-64/kdu_expand /usr/local/bin/kdu_expand && \
    ln -s /usr/local/adore-djatoka-1.1/lib/Linux-x86-64/libkdu_a60R.so /usr/local/lib/libkdu_a60R.so && \
    ln -s /usr/local/adore-djatoka-1.1/lib/Linux-x86-64/libkdu_jni.so /usr/local/lib/libkdu_jni.so && \
    ln -s /usr/local/adore-djatoka-1.1/lib/Linux-x86-64/libkdu_v60R.so /usr/local/lib/libkdu_v60R.so && \
    echo "/usr/local/adore-djatoka-1.1/lib/Linux-x86-64" > /etc/ld.so.conf.d/kdu_libs.conf && \
    ldconfig && \
    cd /usr/local/adore-djatoka-1.1/bin && \
    rm -rf *.bat Solaris-Sparc Solaris-Sparcv9 Solaris-x86 Win32 ../dist/adore-djatoka.war && \
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
    curl -O -L https://www.imagemagick.org/download/ImageMagick.tar.gz && \
    tar xf ImageMagick.tar.gz && \
    cd ImageMagick-* && \
    ./configure --enable-hdri --with-quantum-depth=16 --without-magick-plus-plus --without-perl --with-rsvg && \
    make && \
    make install && \
    ldconfig && \
    ## PHP ImageMagick latest (IMagick)
    cd /tmp && \
    curl -O -L http://pecl.php.net/get/imagick && \
    tar xf imagick && \
    cd imagick-* && \
    phpize && \
    ./configure --with-imagick=/usr/local/bin && \
    make && \
    make install && \
    echo '; configuration for php imagick module \nextension=imagick.so' > /etc/php/7.1/mods-available/imagick.ini && \
    phpenmod imagick && \
    ## Cleanup phase.
    apt-get purge $BUILD_DEPS software-properties-common -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV COMPOSER_HASH=${COMPOSER_HASH:-76a7060ccb93902cd7576b67264ad91c8a2700e2} \    
    FITS_VERSION=${FITS_VERSION:-1.5.0}

## Let's go!  Finalize all remaining: djatoka, composer, drush, fits.
RUN useradd --comment 'Islandora User' --no-create-home -d /var/www/html --system --uid $ISLANDORA_UID --user-group -s /bin/bash islandora && \
    chown -R islandora:www-data /var/www/html && \
    ## Temporary directory for composer, fits, etc...
    mkdir -p /tmp/build && \
    cd /tmp/build/ && \
    ## COMPOSER
    wget -O composer-setup.php https://raw.githubusercontent.com/composer/getcomposer.org/$COMPOSER_HASH/web/installer && \
    php composer-setup.php --filename=composer --install-dir=/usr/local/bin && \
    ## DRUSH 8.x as recommended by @g7morris
    mkdir -p /opt/drush-8.x && \
    cd /opt/drush-8.x && \
    /usr/local/bin/composer init --require=drush/drush:8.* -n && \
    /usr/local/bin/composer config bin-dir /usr/local/bin && \
    /usr/local/bin/composer install && \
    ## FITS
    cd /tmp/build/ && \
    curl -O -L https://github.com/harvard-lts/fits/releases/download/$FITS_VERSION/fits-$FITS_VERSION.zip && \
    mkdir fits-$FITS_VERSION && \
    unzip fits-$FITS_VERSION.zip -d fits-$FITS_VERSION && \
    mv fits-$FITS_VERSION /usr/local/fits && \
    ln -s /usr/local/fits/fits.sh /usr/local/bin/fits && \
    ## The following line will remove TikaTool operations while FITS generates technical metadata, preventing Tika temp files from maxing out disk space as described in ISLE Issue #96. Remove to allow Tika to run
    sed -ie 's/<tool class="edu\.harvard\.hul\.ois\.fits\.tools\.tika\.TikaTool" exclude-exts="jar,avi,mov,mpg,mpeg,mkv,mp4,mpeg4,m2ts,mxf,ogv,mj2,divx,dv,m4v,m2v,ismv" classpath-dirs="lib\/tika"\/>/<!-- & -->/' /usr/local/fits/xml/fits.xml && \    
    ## BUILD TOOLS
    mkdir /utility-scripts && \
    cd /utility-scripts && \
    git clone $ISLE_BUILD_TOOLS_REPO -b $ISLE_BUILD_TOOLS_BRANCH isle_drupal_build_tools && \
    ## Disable Default
    a2dissite 000-default && \
    a2enmod rewrite deflate headers expires proxy proxy_http proxy_html proxy_connect remoteip xml2enc cache_disk && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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
      traefik.port="80" \
      traefik.frontend.entryPoints=http,https

COPY rootfs /

VOLUME /var/www/html

EXPOSE 80

ENTRYPOINT ["/init"]