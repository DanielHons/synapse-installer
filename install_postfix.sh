#!/usr/bin/env bash
echo "Install postfix mailserver"
source CONFIG

DEBIAN_FRONTEND=noninteractive

apt install postfix -y
cp postfix/main.cf /etc/postfix/main.cf
sed -i -e "s/matrix.example.com/${DOMAIN}/g" /etc/postfix/main.cf

sed -i -e "s/#notif_from:/notif_from:/g" ${VIRTUAL_ENV_DIR}/homeserver.yaml

/etc/init.d/postfix restart