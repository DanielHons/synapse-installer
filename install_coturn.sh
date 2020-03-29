#!/usr/bin/env bash
source CONFIG
source ${VIRTUAL_ENV_DIR}/env/bin/activate
apt install coturn -y
echo TURNSERVER_ENABLED=1 >> /etc/default/coturn
cp ${CONFIG_PATH}/coturn/turnserver.conf /etc/turnserver.conf
turnSecret=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
sed -i -e "s/TURN_SECRET/$turnSecret/g" /etc/turnserver.conf
sed -i -e "s/COTURN_DOMAIN/$DOMAIN/g" /etc/turnserver.conf


string="Teststring"
echo """
## TURN ##

# The public URIs of the TURN server to give to clients
#
turn_uris: [“turn:${DOMAIN}:5349”]

# The shared secret used to compute passwords for the TURN server
#
turn_shared_secret: "${turnSecret}"

# The Username and password if the TURN server needs them and
# does not use a token
#
# turn_username: "TURNSERVER_USERNAME"
# turn_password: "TURNSERVER_PASSWORD"

# How long generated TURN credentials last
#
turn_user_lifetime: 1h

# Whether guests should be allowed to use the TURN server.
# This defaults to True, otherwise VoIP will be unreliable for guests.
# However, it does introduce a slight security risk as it allows users to
# connect to arbitrary endpoints without having first signed up for a
# valid account (e.g. by passing a CAPTCHA).
#
turn_allow_guests: true
""" >> ${VIRTUAL_ENV_DIR}/homeserver.yaml

