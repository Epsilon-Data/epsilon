#!/bin/sh
set -eu

# Update file permissions of certificates
mkdir -p /var/lib/postgresql/runtime-certs
cp /var/lib/postgresql/certs/server.crt /var/lib/postgresql/runtime-certs/server.crt
cp /var/lib/postgresql/certs/server.key /var/lib/postgresql/runtime-certs/server.key
chown postgres:postgres /var/lib/postgresql/runtime-certs/server.crt /var/lib/postgresql/runtime-certs/server.key
chmod 644 /var/lib/postgresql/runtime-certs/server.crt
chmod 600 /var/lib/postgresql/runtime-certs/server.key

# Run the base entrypoint
exec /usr/local/bin/docker-entrypoint.sh "$@"