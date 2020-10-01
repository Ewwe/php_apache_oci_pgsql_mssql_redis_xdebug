ARG IMAGE_VERSION
FROM registry.evosoft.cz:5000/php_apache_all_db_chilkat_xdebug:${IMAGE_VERSION}

# Override php.ini with custom settings
COPY ./php_custom_settings.ini $PHP_INI_DIR/conf.d/

# define environments
ARG APACHE_SERVER_NAME
ARG APACHE_HTTP_PORT
ARG APACHE_HTTPS_PORT
ENV APACHE_SERVER_NAME=${APACHE_SERVER_NAME} \
    APACHE_HTTP_PORT=${APACHE_HTTP_PORT} \
    APACHE_HTTPS_PORT=${APACHE_HTTPS_PORT}

# add apache configs
COPY ./apache_http.conf /etc/apache2/sites-available/${APACHE_SERVER_NAME}_http.conf
COPY ./apache_https.conf /etc/apache2/sites-available/${APACHE_SERVER_NAME}_https.conf
COPY ./apache_mods_ssl.conf /etc/apache2/mods-available/apache_mods_ssl.conf

# SUPERVISOR
COPY ./supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY ./supervisor/services_default /etc/supervisor/conf.d/

# adding on_start.sh script
COPY ./on_start.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/on_start.sh

WORKDIR /var/www/app

CMD /usr/local/sbin/on_start.sh && /usr/bin/supervisord -c /etc/supervisor/supervisord.conf



