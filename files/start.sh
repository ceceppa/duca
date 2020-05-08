#!/bin/bash

# Set xdebug.remote_port
if [ -z "$DOCKER_HOST_IP" ]; then
    echo "=> Xdebug not active. Please set the DOCKER_HOST_IP variable to enable it"
else
    echo "=> XDEBUG active on $DOCKER_HOST_IP"
    sed -i s/xdebug.remote_host.*/xdebug.remote_host=$DOCKER_HOST_IP/ /etc/php/7.2/mods-available/xdebug.ini
fi

# Start php service
/etc/init.d/php7.2-fpm start

echo 'Starting nginx'
nginx -g "daemon off;"
