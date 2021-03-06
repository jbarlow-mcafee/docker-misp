#!/usr/bin/env bash

if [ -f /init-db ]; then
   /init-db
fi

if [ -f /.misp_config_default/init-misp-config ]; then
   /.misp_config_default/init-misp-config
fi

if [ ! -f /etc/ssl/private/.ssl_initialized ] && [ ! -f /etc/ssl/private/misp.crt ] && [ ! -f /etc/ssl/private/misp.key ]; then
    openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout /etc/ssl/private/misp.key -out /etc/ssl/private/misp.crt -batch
    touch /etc/ssl/private/.ssl_initialized
fi


if [ -n "${MISP_BASE_URL}" ]; then
    if [[ ! "${MISP_BASE_URL}" =~ ^https?:\/\/ ]]; then
        MISP_BASE_URL="https://${MISP_BASE_URL}"
    fi
    sed -i -E "s/'baseurl'(\s+).*'.*'/'baseurl' => '${MISP_BASE_URL//\//\\/}'/" /var/www/MISP/app/Config/config.php
fi

/usr/bin/supervisord -c "/etc/supervisor/conf.d/supervisord.conf"
