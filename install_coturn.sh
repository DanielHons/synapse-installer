#!/usr/bin/env bash
apt install coturn -y
echo TURNSERVER_ENABLED=1 >> /etc/default/coturn
cp ${CONFIG_PATH}/coturn/turnserver.conf /etc/turnserver.conf

turnSecret=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
sed -i -e "s/TURN_SECRET/$turnSecret/g" /etc/turnserver.conf
sed -i -e "s/COTURN_DOMAIN/$DOMAIN/g" /etc/turnserver.conf

# TODO edit synapse conf

sudo systemctl restart matrix-synapse