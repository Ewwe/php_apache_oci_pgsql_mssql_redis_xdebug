FROM php:7.4-apache-buster

ARG DEBIAN_FRONTEND=noninteractive
ARG ACCEPT_EULA=Y

ENV ORACLE_INSTALLER_PATH="/usr/local/lib"
# copy oci drivers
COPY ./oracle_drivers/ $ORACLE_INSTALLER_PATH

ENV LD_LIBRARY_PATH="$ORACLE_INSTALLER_PATH/instantclient_12_2"
ENV TNS_ADMIN="$ORACLE_INSTALLER_PATH/instantclient_12_2"
ENV ORACLE_BASE="$ORACLE_INSTALLER_PATH/instantclient_12_2"
ENV ORACLE_HOME="$ORACLE_INSTALLER_PATH/instantclient_12_2"
ENV NLS_LANG=".AL32UTF8"

RUN     cp /etc/apt/sources.list /etc/apt/sources.list~ \
        && sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list \
        && apt-get update && apt-get install -y \
        # basics
        cmake \
        apt-transport-https \
        lsb-release \
        ca-certificates \
        wget \
        nodejs \
        npm \
        mc \
        git \
        nano \
        cron \
        openssh-client \
        gettext-base \
        unzip \
        supervisor \
        # php extensions dependencies
        gnupg \
        libzip-dev \
        zip \
        libxml2-dev \
        libpq-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libldap2-dev \
        # oracle dependencies, f*** me :D
        libaio1 \
        libaio-dev \
        # Use the default production php configuratio
        && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
        # Microsoft SQL Drivers dependencies
        && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
        && curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list \
        && apt-get update && apt-get -y --no-install-recommends install \
            unixodbc-dev \
            msodbcsql17 \
        # Install Oracle Instantclient
        && unzip -q $ORACLE_INSTALLER_PATH/instantclient-basic-linux.x64-12.2.0.1.0.zip -d $ORACLE_INSTALLER_PATH/ \
        && unzip -q $ORACLE_INSTALLER_PATH/instantclient-sdk-linux.x64-12.2.0.1.0.zip -d $ORACLE_INSTALLER_PATH/ \
        && unzip -q $ORACLE_INSTALLER_PATH/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip -d $ORACLE_INSTALLER_PATH/ \
        && ln -s $ORACLE_INSTALLER_PATH/instantclient_12_2/libclntsh.so.12.1 $ORACLE_INSTALLER_PATH/instantclient_12_2/libclntsh.so \
        && ln -s $ORACLE_INSTALLER_PATH/instantclient_12_2/libclntshcore.so.12.1 $ORACLE_INSTALLER_PATH/instantclient_12_2/libclntshcore.so \
        && ln -s $ORACLE_INSTALLER_PATH/instantclient_12_2/libocci.so.12.1 $ORACLE_INSTALLER_PATH/instantclient_12_2/libocci.so \
        && ln -s $ORACLE_INSTALLER_PATH/sqlplus /usr/sbin/sqlplus \
        # install php extensions
        && docker-php-ext-configure zip --with-libzip \
        && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
        && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,$ORACLE_INSTALLER_PATH/instantclient_12_2 \
        && echo 'instantclient,$ORACLE_INSTALLER_PATH/instantclient_12_2' | pecl install oci8 \
        && docker-php-ext-install \
            zip \
            soap \
            gd \
            ldap \
            bcmath \
            pdo_oci \
            pdo_mysql \
            pdo pdo_pgsql pgsql \
        && docker-php-ext-enable \
            oci8 \
        # redis
        && pecl install redis \
        && docker-php-ext-enable \
            redis \
        && pecl install xdebug \
        && docker-php-ext-enable xdebug \
        # Microsoft ODBC
        && pecl install \
            sqlsrv \
            pdo_sqlsrv \
        && docker-php-ext-enable \
            sqlsrv \
            pdo_sqlsrv \
        # Clean up
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* $ORACLE_INSTALLER_PATH/instantclient*.zip


RUN   echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
      echo "xdebug.remote_port=8888" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
      echo "xdebug.auto_trace=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
      echo "xdebug.show_mem_delta=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
      echo "xdebug.trace_enable_trigger=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
      echo "xdebug.show_mem_delta=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
      echo "xdebug.trace_format=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
      echo "xdebug.profiler_enable=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
      echo "xdebug.profiler_enable_trigger=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini;

# installing composer
RUN set -e; \
    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"; \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"; \
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"; \
    \
    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; \
    then \
        >&2 echo 'ERROR: Invalid installer signature'; \
        rm composer-setup.php; \
        exit 1; \
    fi; \
    \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer; \
    rm composer-setup.php; \
    adduser --disabled-password --gecos "" composer; \
    su composer -c "composer global require hirak/prestissimo"

