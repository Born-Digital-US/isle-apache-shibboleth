ARG BASE=ubuntu:bionic
FROM $BASE as s6-overlay-base

##
LABEL "io.github.islandora-collaboration-group.name"="isle-apache" \
      "io.github.islandora-collaboration-group.description"="ISLE Apache container, responsible for serving Drupal and Islandora's presentation layer!\
A default site called isle.localdomain is prepared for those looking to explore Islandora for the first time!" \
      "io.github.islandora-collaboration-group.license"="Apache-2.0" \
      "io.github.islandora-collaboration-group.vcs-url"="git@github.com:Islandora-Collaboration-Group/ISLE.git" \
      "io.github.islandora-collaboration-group.vendor"="Islandora Collaboration Group (ICG) - islandora-consortium-group@googlegroups.com" \
      "io.github.islandora-collaboration-group.maintainer"="Islandora Collaboration Group (ICG) - islandora-consortium-group@googlegroups.com"
##

## S6-Overlay @see: https://github.com/just-containers/s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.4.0/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C / && \
    rm /tmp/s6-overlay-amd64.tar.gz

ENV INITRD=no

RUN GEN_DEP_PACKS="software-properties-common \
    language-pack-en-base \
    cron \
    wget \
    dnsutils \
    curl \
    nano \
    vim \
    rsync\
    git \
    zip \
    unzip \
    bzip2" && \
    ## Prepare APT entirely.
    apt-get update && \
    echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 boolean true' | debconf-set-selections && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && \
    apt-get install --no-install-recommends -y $GEN_DEP_PACKS && \
    add-apt-repository -y ppa:webupd8team/java && \
    add-apt-repository -y ppa:ondrej/php && \
    add-apt-repository -y ppa:ondrej/apache2 && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en

FROM s6-overlay-base as final
RUN APACHE_PACKAGES="apache2 \
    oracle-java8-installer \
    oracle-java8-set-default \
    openssh-client \
    tmpreaper \
    mysql-client \
    python-mysqldb \
    libmysqlclient-dev \
    openssl \
    libxml2-dev \
    php5.6  \
    libapache2-mod-php5.6 \
    libcurl3-openssl-dev \
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
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    imagemagick \
    ffmpeg \
    php5.6-imagick \
    poppler-utils \
    bibutils \
    libimage-exiftool-perl \
    xpdf \
    lame \
    x264 \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    zlib1g-dev \
    libtool \
    libtiff-dev \
    libjpeg-dev \
    libpng-dev \
    giflib-tools \
    libgif-dev \
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
    apt-mark hold ghostscript && \
    apt-get install --no-install-recommends -y $APACHE_PACKAGES && \
    apt-get purge -y --auto-remove openjdk* && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    cd /opt && \
    wget https://sourceforge.mirrorservice.org/d/dj/djatoka/djatoka/1.1/adore-djatoka-1.1.tar.gz && \
    tar -xzf adore-djatoka-1.1.tar.gz && \
    rm adore-djatoka-1.1.tar.gz && \
    sed -i 's/DJATOKA_HOME=`pwd`/DJATOKA_HOME=\/opt\/adore-djatoka-1.1/g' /opt/adore-djatoka-1.1/bin/env.sh && \
    sed -i 's|`uname -p` = "x86_64"|`uname -m` = "x86_64"|' /opt/adore-djatoka-1.1/bin/env.sh && \
    touch /etc/ld.so.conf.d/kdu_libs.conf && \
    echo "/opt/adore-djatoka-1.1/lib/Linux-x86-64" > /etc/ld.so.conf.d/kdu_libs.conf && \
    chmod 444 /etc/ld.so.conf.d/kdu_libs.conf && \
    chown root:root /etc/ld.so.conf.d/kdu_libs.conf && \
    # touch /etc/apache2/conf-available/servername.conf && \
    # echo 'ServerName localhost' > /etc/apache2/conf-available/servername.conf && \
    touch /etc/cron.d/tmpreaper-cron && \
    echo "0 */12 * * * root /usr/sbin/tmpreaper -am 4d /tmp >> /var/log/cron.log 2>&1" | tee /etc/cron.d/tmpreaper-cron && \
    chmod 0644 /etc/cron.d/tmpreaper-cron

###
# Set up environmental variables for tomcat & dependencies installation
ENV JAVA_HOME=/usr/lib/jvm/java-8-oracle \
    JRE_HOME=/usr/lib/jvm/java-8-oracle/jre \
    PATH=$PATH:$HOME/.composer/vendor/bin:/usr/lib/jvm/java-8-oracle/bin:/usr/lib/jvm/java-8-oracle/jre/bin \
    KAKADU_LIBRARY_PATH=/opt/adore-djatoka-1.1/lib/Linux-x86-64 \
    KAKADU_HOME=/opt/adore-djatoka-1.1/lib/Linux-x86-64

COPY rootfs /

# Finalize... (uhg --)
# RUN mkdir -p /tmp/build && \
#     cd /tmp/build && \
#     wget -O composer-setup.php https://raw.githubusercontent.com/composer/getcomposer.org/2091762d2ebef14c02301f3039c41d08468fb49e/web/installer && \
#     php composer-setup.php --filename=composer --install-dir=/usr/local/bin && \
#     cd / && \
#     rm -rf /tmp/build && \
#     cd /home/islandora && \
#     mkdir -p /opt/drush-7.x && \
#     cd /opt/drush-7.x && \
#     /usr/local/bin/composer init --require=drush/drush:7.* -n && \
#     /usr/local/bin/composer config bin-dir /usr/local/bin && \
#     /usr/local/bin/composer install && \
#     chmod 755 /opt/drush-7.x && \
#     chown -R islandora:www-data /opt/drush-7.x && \
#     chown -R islandora:www-data /opt/adore-djatoka-1.1 && \
#     chmod -R g+rwx /opt/adore-djatoka-1.1 && \
#     chmod 655 /opt/adore-djatoka-1.1/bin/env.sh && \
#     chown islandora:www-data /opt/adore-djatoka-1.1/bin/env.sh && \
#     chmod 655 /opt/adore-djatoka-1.1/bin/envinit.sh && \
#     chown islandora:www-data /opt/adore-djatoka-1.1/bin/envinit.sh && \
#     chown root:root /etc/ld.so.conf.d/kdu_libs.conf && \
#     chmod 444 /etc/ld.so.conf.d/kdu_libs.conf && \
#     ln -s /opt/adore-djatoka-1.1/bin/Linux-x86-64/kdu_compress /usr/local/bin/kdu_compress && \
#     ln -s /opt/adore-djatoka-1.1/bin/Linux-x86-64/kdu_expand /usr/local/bin/kdu_expand && \
#     ln -s /opt/adore-djatoka-1.1/lib/Linux-x86-64/libkdu_a60R.so /usr/local/lib/libkdu_a60R.so && \
#     ln -s /opt/adore-djatoka-1.1/lib/Linux-x86-64/libkdu_jni.so /usr/local/lib/libkdu_jni.so && \
#     ln -s /opt/adore-djatoka-1.1/lib/Linux-x86-64/libkdu_v60R.so /usr/local/lib/libkdu_v60R.so && \
#     chown -h islandora:www-data /usr/local/bin/kdu_compress && \
#     chown -h islandora:www-data /usr/local/bin/kdu_expand && \
#     chown -h islandora:www-data /usr/local/lib/libkdu_a60R.so && \
#     chown -h islandora:www-data /usr/local/lib/libkdu_jni.so && \
#     chown -h islandora:www-data /usr/local/lib/libkdu_v60R.so && \
#     /sbin/ldconfig && \
#     cd /home/islandora && \
#     wget https://projects.iq.harvard.edu/files/fits/files/fits-1.2.0.zip && \
#     unzip fits-1.2.0.zip && \
#     mv /home/islandora/fits-1.2.0 /usr/local/fits && \
#     chown -R islandora:www-data /usr/local/fits && \
#     chmod -R g+rwx /usr/local/fits && \
#     cd /usr/local/fits/ && \
#     chmod 775 fits-env.sh && \
#     chmod 775 fits-ngserver.sh && \
#     chmod 775 fits.sh && \
#     rm /home/islandora/fits-1.2.0.zip && \
#     touch /var/log/cron.log && \
#     pecl install uploadprogress && \
#     echo 'extension=uploadprogress.so' >> /etc/php/5.6/apache2/php.ini && \
#     sed -i 's/memory_limit = .*/memory_limit = '256M'/' /etc/php/5.6/apache2/php.ini && \
#     sed -i 's/upload_max_filesize = .*/upload_max_filesize = '2000M'/' /etc/php/5.6/apache2/php.ini && \
#     sed -i 's/post_max_size = .*/post_max_size = '2000M'/' /etc/php/5.6/apache2/php.ini && \
#     sed -i 's/max_input_time = .*/max_input_time = '-1'/' /etc/php/5.6/apache2/php.ini && \
#     sed -i 's/max_execution_time = .*/max_execution_time = '0'/' /etc/php/5.6/apache2/php.ini && \
#     # a2enconf servername && \
#     mkdir -p /var/www/html && \
#     chown islandora:www-data /var/www/html && \
#     chmod -R 777 /var/www/html && \
#     chown -R islandora:www-data /var/www/html && \
#     chown islandora:www-data /usr/local/bin/ffmpeg && \
#     chown islandora:www-data /usr/local/bin/ffprobe && \
#     chown islandora:www-data /usr/local/bin/ffserver && \
#     chown islandora:www-data /usr/local/bin/qt-faststart && \
#     chown islandora:www-data /usr/bin/lame && \
#     chown islandora:www-data /usr/bin/x264 && \
#     chown islandora:www-data /usr/bin/xtractprotos && \
#     a2dissite 000-default && \
#     a2dissite default-ssl && \
#     a2ensite isle_localdomain_ssl.conf && \
#     a2ensite isle_localdomain.conf && \
#     a2enmod ssl rewrite deflate headers expires proxy proxy_http proxy_html proxy_connect remoteip xml2enc

VOLUME /var/www/html

# Make sure ports 80 and 443 are available to the internal network.
EXPOSE 80 443

###
# Run the Apache web server
ENTRYPOINT ["/init"]