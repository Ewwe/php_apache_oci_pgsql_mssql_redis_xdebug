#!/bin/bash
set -e

### COPIED FROM OFFICIAL IMAGE https://github.com/docker-library/php/blob/master/7.3/buster/apache/apache2-foreground
# Note: we don't just use "apache2ctl" here because it itself is just a shell-script wrapper around apache2 which provides extra functionality like "apache2ctl start" for launching apache2 in the background.
# (also, when run as "apache2ctl <apache args>", it does not use "exec", which leaves an undesirable resident shell process)

: "${APACHE_CONFDIR:=/etc/apache2}"
: "${APACHE_ENVVARS:=$APACHE_CONFDIR/envvars}"
if test -f "$APACHE_ENVVARS"; then
	. "$APACHE_ENVVARS"
fi

# Apache gets grumpy about PID files pre-existing
: "${APACHE_RUN_DIR:=/var/run/apache2}"
: "${APACHE_PID_FILE:=$APACHE_RUN_DIR/apache2.pid}"
rm -f "$APACHE_PID_FILE"

# create missing directories
# (especially APACHE_RUN_DIR, APACHE_LOCK_DIR, and APACHE_LOG_DIR)
for e in "${!APACHE_@}"; do
	if [[ "$e" == *_DIR ]] && [[ "${!e}" == /* ]]; then
		# handle "/var/lock" being a symlink to "/run/lock", but "/run/lock" not existing beforehand, so "/var/lock/something" fails to mkdir
		#   mkdir: cannot create directory '/var/lock': File exists
		dir="${!e}"
		while [ "$dir" != "$(dirname "$dir")" ]; do
			dir="$(dirname "$dir")"
			if [ -d "$dir" ]; then
				break
			fi
			absDir="$(readlink -f "$dir" 2>/dev/null || :)"
			if [ -n "$absDir" ]; then
				mkdir -p "$absDir"
			fi
		done

		mkdir -p "${!e}"
	fi
done
###

### PHP INI
# To make sure any user on system can read (but not edit it)
chmod 644 /usr/local/etc/php/conf.d/php_custom_settings.ini
###

### APACHE CONFIGS
# if config wasn't added yet (restart container vs. first deploy container).
if ! ls /etc/apache2/sites-enabled/${APACHE_SERVER_NAME}*.conf 1> /dev/null 2>&1; then
    cd /etc/apache2/sites-available && a2dissite --quiet *
    a2enmod --quiet rewrite
    # enable https
    if [ "$(echo $APACHE_HTTPS_PORT | tr '[:upper:]' '[:lower:]')" = "false" ]; then
        a2ensite --quiet ${APACHE_SERVER_NAME}_http.conf
    else
        if [ ! -f /etc/ssl/private/dhparams.pem ]; then
            echo >&2 "***"
            echo >&2 "* dhparams.pem is missing!"
            echo >&2 "* generate it with command 'openssl dhparam -out <host_path>/dhparams.pem 2048'!"
            echo >&2 "* then mount it '-v <host_path>:/etc/ssl/private/dhparams.pem:ro'"
            echo >&2 "***"
            exit 1
        fi
        if [ -f /etc/ssl/letsencrypt/fullchain.pem ]; then
            echo >&2 "***"
            echo >&2 "* fullchain.pem is missing!"
            echo >&2 "* mount it '-v <host_path>:/etc/ssl/letsencrypt/fullchain.pem:ro'"
            echo >&2 "***"
            exit 1
        fi
        if [ -f /etc/ssl/letsencrypt/privkey.pem ]; then
            echo >&2 "***"
            echo >&2 "* fullchain.pem is missing!"
            echo >&2 "* mount it '-v <host_path>:/etc/ssl/letsencrypt/privkey.pem:ro'"
            echo >&2 "***"
            exit 1
        fi
        chmod 600 /etc/ssl/private/dhparams.pem
        a2enmod --quiet ssl
        a2enmod --quiet headers
        a2ensite --quiet ${APACHE_SERVER_NAME}_https.conf
    fi
fi
###

### Reinit permissions https://askubuntu.com/questions/767504/permissions-problems-with-var-www-html-and-my-own-home-directory-for-a-website
    echo "Reinit permissions..."
    #chown -R root:www-data /var/www/officeerp/
    # every new file will be created with www-data group
    find /var/www/app/www -type d -exec chmod g+s {} +
    # nette dependencies log and temp must have write permissons
    mkdir -p /var/www/app/log
    chmod a+rw /var/www/app/log
    mkdir -p /var/www/app/temp
    chmod a+rw /var/www/app/temp

###