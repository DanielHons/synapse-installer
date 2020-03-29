#!/usr/bin/env bash
set -e
echo "Install postgres database"
source CONFIG

DEBIAN_FRONTEND=noninteractive

apt install postgresql postgresql-client -y

sed -i -e 's/#listen_addresses/listen_addresses/' /etc/postgresql/11/main/postgresql.conf
systemctl restart postgresql

pgPassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

su -s /bin/bash postgres -c ./database/postgres-init.sh $pgPassword

sed "s/POSTGRES_PASSWORD/$pgPassword/g" database/postgres-conf.yaml  >> ${VIRTUAL_ENV_DIR}/homeserver.yaml




