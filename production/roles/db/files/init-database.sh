#!/bin/bash

set -e

EXISTS=$(psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='www-data'")

if [ "${EXISTS}" == "" ] ; then
  createuser --username "$POSTGRES_USER" www-data -S -R -d
fi

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --set password="$POSTGRES_PASSWORD" <<-EOSQL
	ALTER USER "www-data" WITH PASSWORD :'password' ;
EOSQL
