#!/usr/bin/env bash

pgPassword=$1

psql -v ON_ERROR_STOP=1  <<-EOSQL
CREATE USER synapse_user WITH PASSWORD '$pgPassword';
CREATE DATABASE synapse
 ENCODING 'UTF8'
 LC_COLLATE='C'
 LC_CTYPE='C'
 template=template0
 OWNER synapse_user;
EOSQL


