#!/bin/bash

set -e

PASSWORD="$(cat /run/secrets/db-password)"

createuser --username "$POSTGRES_USER" www-data -S -R -d

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	ALTER USER "www-data" WITH PASSWORD '${PASSWORD}';
EOSQL
