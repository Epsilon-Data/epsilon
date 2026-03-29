#!/bin/sh
set -eu

REALM="${KEYCLOAK_REALM:-epsilon}"
REL_PATH="${KC_HTTP_RELATIVE_PATH:-/}"
PROFILE_JSON="/opt/keycloak/user-profile.json"

case "$REL_PATH" in
  /*) : ;;
  *) REL_PATH="/$REL_PATH" ;;
esac
REL_PATH="${REL_PATH%/}"

echo "[kc] Starting Keycloak with args: ${*:-start}"
/opt/keycloak/bin/kc.sh ${*:-start} &

KC_PID="$!"

echo "[kc] Waiting for readiness on 9000 at ${REL_PATH}/health/ready ..."
i=0
while :; do
  i=$((i+1))
  if [ "$i" -gt 180 ]; then
    echo "[kc] ERROR: Keycloak not ready after 180s"
    kill "$KC_PID" >/dev/null 2>&1 || true
    exit 1
  fi

  if sh -c 'exec 3<>/dev/tcp/127.0.0.1/9000 && \
            printf "GET '"${REL_PATH}"'/health/ready HTTP/1.1\r\nhost: 127.0.0.1:9000\r\n\r\n" >&3 && \
            timeout --preserve-status 1 cat <&3 | grep -m 1 -q "UP"' 2>/dev/null; then
    break
  fi

  sleep 1
done

echo "[kc] Applying user profile schema to realm: ${REALM}"
/opt/keycloak/bin/kcadm.sh config credentials \
  --server "http://127.0.0.1:8080${REL_PATH}" \
  --realm master \
  --user "${KEYCLOAK_ADMIN}" \
  --password "${KEYCLOAK_ADMIN_PASSWORD}" >/dev/null

/opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE >/dev/null

/opt/keycloak/bin/kcadm.sh update users/profile \
  -r "${REALM}" \
  -f "${PROFILE_JSON}" >/dev/null

echo "[kc] User profile applied. Continuing to run Keycloak."
wait "$KC_PID"
