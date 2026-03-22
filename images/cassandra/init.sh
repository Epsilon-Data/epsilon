#!/bin/bash

set -euo pipefail

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                         ⚙️  Initialising Cassandra...                     ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""


: "${CASSANDRA_EPSILON_PASSWORD:?CASSANDRA_EPSILON_PASSWORD is required}"
: "${CASSANDRA_ADMIN_PASSWORD:?CASSANDRA_ADMIN_PASSWORD is required}"

HOST="${CASSANDRA_HOST:-cassandra}"
PORT="${CASSANDRA_PORT:-9042}"
DEFAULT_PASS="${CASSANDRA_DEFAULT_PASSWORD:-cassandra}"

# wait for the port to open (no auth involved)
echo "Waiting for Cassandra TCP $HOST:$PORT..."
until timeout 2 bash -lc "cat < /dev/null > /dev/tcp/$HOST/$PORT" 2>/dev/null; do
  sleep 2
done

# pick working credentials (try admin first, then default)
echo "Waiting for Cassandra CQL to be ready..."
while true; do
  if timeout 5 cqlsh "$HOST" "$PORT" -u cassandra -p "$CASSANDRA_ADMIN_PASSWORD" \
      -e "SELECT now() FROM system.local;" >/dev/null 2>&1; then
    ADMIN_PASS="$CASSANDRA_ADMIN_PASSWORD"
    break
  fi

  if timeout 5 cqlsh "$HOST" "$PORT" -u cassandra -p "$DEFAULT_PASS" \
      -e "SELECT now() FROM system.local;" >/dev/null 2>&1; then
    ADMIN_PASS="$DEFAULT_PASS"
    break
  fi

  sleep 2
done

echo "Seeding roles..."
# create new admin_user (epsilon)
cqlsh "$HOST" "$PORT" -u cassandra -p "$ADMIN_PASS" <<EOF
  CREATE ROLE IF NOT EXISTS epsilon
  WITH PASSWORD = '${CASSANDRA_EPSILON_PASSWORD}'
  AND SUPERUSER = true
  AND LOGIN = true;

  -- enforce desired state on reruns
  ALTER ROLE epsilon WITH PASSWORD = '${CASSANDRA_EPSILON_PASSWORD}';
  ALTER ROLE epsilon WITH SUPERUSER = true;
  ALTER ROLE epsilon WITH LOGIN = true;
EOF

echo "Done initialising Cassandra!"
echo "#############################################################################"