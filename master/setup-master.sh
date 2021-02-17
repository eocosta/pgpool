#!/bin/bash
echo "host replication all 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"

set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

CREATE USER $PG_REP_USER REPLICATION LOGIN CONNECTION LIMIT 100 ENCRYPTED PASSWORD '$PG_REP_PASSWORD';

EOSQL

mkdir -p $PGDATA/archive
chmod 700 $PGDATA/archive -R
chown -R postgres:postgres $PGDATA/archive

# Novo
cat >> ${PGDATA}/postgresql.conf <<EOF
wal_level = replica
max_wal_senders = 3
wal_keep_segments = 64
listen_addresses = '*'
archive_mode = on
archive_command = 'cp %p $PGDATA/%f'
synchronous_commit = local
synchronous_standby_names = 'pgslave001'
EOF
