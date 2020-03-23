#!/usr/bin/env bash
#source ./CONFIG
#echo $VIRTUAL_ENV_DIR

echo "    bind_addresses: ['::1', '127.0.0.1']" > test.txt
sed -i -e 's///g' test.txt
cat test.txt
