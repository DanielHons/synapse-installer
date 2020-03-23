#!/usr/bin/env bash
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

# Remove bind to ::1
sed -i -e "s/'::1',//g" homeserver.yaml

apt-get update
apt-get install software-properties-common -y
add-apt-repository ppa:certbot/certbot -y
apt-get update
apt-get install certbot python-certbot-nginx -y

certbot certonly --nginx -m ${EMAIL_ADDRESS}  --agree-tos -d $DOMAIN

(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

cp nginx.conf /etc/nginx/conf.d/matrix.conf
sed -i -e "s/matrix.example.com/${DOMAIN}/g" /etc/nginx/conf.d/matrix.conf

cp homeserver.yaml ${VIRTUAL_ENV_DIR}/homeserver.yaml
sed -i -e "s/matrix.example.com/${DOMAIN}/g" ${VIRTUAL_ENV_DIR}/homeserver.yaml

systemctl restart nginx
systemctl enable nginx