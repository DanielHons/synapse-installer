#!/usr/bin/env bash
set -e
CONFIG_PATH="$PWD"
source CONFIG
apt update
apt-get install build-essential virtualenv python3-dev libffi-dev \
  python-pip python-setuptools sqlite3 \
  libssl-dev python-virtualenv libjpeg-dev libxslt1-dev -y



mkdir -p ${VIRTUAL_ENV_DIR}
virtualenv -p python3 ${VIRTUAL_ENV_DIR}/env
source ${VIRTUAL_ENV_DIR}/env/bin/activate

pip install --upgrade pip virtualenv six packaging appdirs
pip install --upgrade setuptools
pip install -U matrix-synapse


cd ${VIRTUAL_ENV_DIR}
python -m synapse.app.homeserver \
  --server-name ${DOMAIN} \
  --config-path homeserver.yaml \
  --generate-config \
  --report-stats=yes



apt-get install software-properties-common -y

cd ${CONFIG_PATH}
echo "Configuring homeserver"
cp homeserver.yaml ${VIRTUAL_ENV_DIR}/homeserver.yaml
sed -i -e "s/matrix.example.com/${DOMAIN}/g" ${VIRTUAL_ENV_DIR}/homeserver.yaml
sed -i -e "s/riot.example.com/${RIOT_DOMAIN}/g" ${VIRTUAL_ENV_DIR}/homeserver.yaml

formSecret=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
sed -i -e "s/__form__secret__/${formSecret}/g" ${VIRTUAL_ENV_DIR}/homeserver.yaml

macaroonSecret=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
sed -i -e "s/__macaroon__secret__/${macaroonSecret}/g" ${VIRTUAL_ENV_DIR}/homeserver.yaml

registrationSharedSecret=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
sed -i -e "s/__registration_shared_secret__/${registrationSharedSecret}/g" ${VIRTUAL_ENV_DIR}/homeserver.yaml

source ./install_postgres.sh




echo "Initialize TLS"
apt-get install certbot python-certbot-nginx -y

source CONFIG
source ${VIRTUAL_ENV_DIR}/env/bin/activate
certbot certonly --nginx -m ${EMAIL_ADDRESS}  --agree-tos -d $DOMAIN

(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

cp nginx/nginx-synapse.conf /etc/nginx/conf.d/matrix.conf

source CONFIG
echo "Configuring reverse proxy for $DOMAIN"
sed -i -e "s/matrix.example.com/${DOMAIN}/g" /etc/nginx/conf.d/matrix.conf
sed -i -e "s/riot.example.com/${RIOT_DOMAIN}/g" /etc/nginx/conf.d/matrix.conf

echo "Start web server"
systemctl enable nginx

echo "Install Riot"
cd ~
wget https://github.com/vector-im/riot-web/releases/download/v1.5.14-rc.1/riot-v1.5.14-rc.1.tar.gz
mkdir riot
tar -xzf riot-v1.5.14-rc.1.tar.gz -C riot
rm riot-v1.5.14-rc.1.tar.gz
mv riot/riot-v1.5.14-rc.1/ /var/www/riot/

certbot certonly --nginx -m ${EMAIL_ADDRESS}  --agree-tos -d $RIOT_DOMAIN
cp ${CONFIG_PATH}/nginx/nginx-riot.conf /etc/nginx/conf.d/riot.conf
sed -i -e "s/riot.example.com/${RIOT_DOMAIN}/g" /etc/nginx/conf.d/riot.conf

cp ${CONFIG_PATH}/riot/riot-config.json /var/www/riot/config.json
sed -i -e "s/matrix.example.com/${DOMAIN}/g" /var/www/riot/config.json
sed -i -e "s/riot.example.com/${RIOT_DOMAIN}/g" /var/www/riot/config.json
sed -i -e "s/jitsi.example.com/${JITSI_HOST}/g" /var/www/riot/config.json

echo "Install Coturn"
source ${CONFIG_PATH}/install_coturn.sh
echo "Restarting nginx"
systemctl restart nginx

cd ${CONFIG_PATH}
echo "Restarting matrix"
source CONFIG
source ${VIRTUAL_ENV_DIR}/env/bin/activate
synctl restart
echo "Create initial user"
register_new_matrix_user -u ${SYNAPSE_USERNAME} -p ${SYNAPSE_USER_PASSWORD} -a -c homeserver.yaml http://localhost:8008