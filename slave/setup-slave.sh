#!/bin/bash

if [ ! -s "$PGDATA/$PG_VERSION" ]; then
	echo "*:*:*:$PG_REP_USER:$PG_REP_PASSWORD" > ~/.pgpass
	chmod 0600 ~/.pgpass

	until ping -c 1 -W 1 pg_master_1
	do
		echo "Waiting for master to ping..."
		sleep 1s
	done
	until pg_basebackup -h pg_master_1 -D ${PGDATA} -U ${PG_REP_USER} -vP -W -log
	do
		echo "Waiting for master to connect..."
		sleep 1s
	done
	echo "host replication all 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"
	set -e

	cat > ${PGDATA}/recovery.conf <<EOF
	standby_mode = on
	primary_conninfo = 'host=pg_master_1 port=5432 user=$PG_REP_USER password=$PG_REP_PASSWORD application_name=baruque'
EOF
	chown postgres. ${PGDATA} -R
	chmod 700 ${PGDATA} -R


fi
# Antigo
# sed -i 's/wal_level = hot_standby/wal_level = replica/g' ${PGDATA}/postgresql.conf

# Novo
cat >> ${PGDATA}/postgresql.conf <<EOF
hot_standby = on
wal_level = replica
max_wal_senders = 3
wal_keep_segments = 64
listen_addresses = '*'
archive_mode = on
archive_command = 'cp %p $PGDATA/%f'
synchronous_commit = local
synchronous_standby_names = 'pgslave001'
EOF

exec "$@"

