#!/bin/sh
set -euo

#install jQ and CURL
apk add --no-cache curl jq >/dev/null

: "${VAULT_ADDR:?VAULT_ADDR is required}"
: "${VAULT_DEV_MODE:=false}"

INIT_JSON=/bootstrap/init.json
INIT_DONE=/bootstrap/.initDone

is_initialized() { curl -fsS "${VAULT_ADDR}/v1/sys/init" | grep -q '"initialized":true'; }
is_sealed() { curl -fsS "${VAULT_ADDR}/v1/sys/seal-status" | grep -q '"sealed":true'; }


echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                         🧭  Setting up Vault...                       ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

# Wait for Vault
echo "Waiting for Vault at ${VAULT_ADDR}..."
until curl -fsS "${VAULT_ADDR}/v1/sys/health?uninitcode=200&sealedcode=200" >/dev/null 2>&1; do
  sleep 1
done
echo "#############################################################################"
#check if dev
if [ "${VAULT_DEV_MODE}" = "false" ]; then
  # Init (only once)
  if ! is_initialized; then
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                         ⚙️  Initialising Vault...                     ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo ""
    vault operator init -format=json > "${INIT_JSON}"
    echo "INFO! initialising Vault done"
  fi

  # check if init json exists
  if [ ! -f "${INIT_JSON}" ]; then
    echo "ERROR! Vault is initialized but ${INIT_JSON} is missing. Cannot bootstrap safely."
    exit 1
  fi

  # Unseal only if sealed AND unseal keys are present (manual unseal mode)
  if is_sealed; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                         🔓  Unsealing Vault...                     ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""
    # If auto-unseal is enabled, there may be no unseal_keys_b64 (or they aren't needed)
    if jq -e '.unseal_keys_b64 and (.unseal_keys_b64 | length) >= 3' "${INIT_JSON}" >/dev/null 2>&1; then
      echo "Unsealing (manual unseal)..."
      UNSEAL_KEY_1="$(jq -r '.unseal_keys_b64[0]' "${INIT_JSON}")"
      UNSEAL_KEY_2="$(jq -r '.unseal_keys_b64[1]' "${INIT_JSON}")"
      UNSEAL_KEY_3="$(jq -r '.unseal_keys_b64[2]' "${INIT_JSON}")"
      vault operator unseal "${UNSEAL_KEY_1}"
      vault operator unseal "${UNSEAL_KEY_2}"
      vault operator unseal "${UNSEAL_KEY_3}"
      echo "INFO! unsealing Vault done"
    else
      echo "ERROR! Vault is sealed and no unseal keys are available. Auto-unseal likely failing."
      exit 1
    fi
  fi

  # Check if vault is already initialised
  if [ -f "${INIT_DONE}" ]; then
    : "${VAULT_ADMIN_PASSWORD:?VAULT_ADMIN_PASSWORD is required}"    
    echo "INFO! bootstrap has already completed, checking for any updates..."
    # login with admin user
    vault login -method=userpass username=admin password="${VAULT_ADMIN_PASSWORD}" >/dev/null
  else
    # check if ROOT_TOKEN exists
    ROOT_TOKEN="$(jq -r '.root_token // empty' "${INIT_JSON}")"
    if [ -z "${ROOT_TOKEN}" ]; then
      echo "ERROR! root_token missing in ${INIT_JSON}"
      exit 1
    fi
    # login for bootstrap steps
    vault login "${ROOT_TOKEN}" >/dev/null
  fi
else
  if [ -z "${VAULT_DEV_ROOT_TOKEN_ID}" ]; then
    echo "ERROR! DEV_ROOT_TOKEN_ID environment variable not set"
    exit 1
  fi
  echo "WARNING! dev mode is enabled! In this mode, Vault runs entirely in-memory"
  # login with DEV token
  vault login "$VAULT_DEV_ROOT_TOKEN_ID" >/dev/null
fi

# policies (safe to re-apply)
vault policy write connector /policies/connector.hcl
vault policy write coordinator-ec2 /policies/coordinator-ec2.hcl
vault policy write ops-admin /policies/ops-admin.hcl

# userpass + admin user
: "${VAULT_ADMIN_PASSWORD:?VAULT_ADMIN_PASSWORD is required}"
if ! vault auth list | grep -q '^userpass/'; then
  vault auth enable userpass
fi
vault write auth/userpass/users/admin \
  password="${VAULT_ADMIN_PASSWORD}" \
  token_policies="ops-admin"

# transit + key (idempotent)
if ! vault secrets list | grep -q '^transit/'; then
  vault secrets enable transit
fi

if [ ! -f /bootstrap/.initDone ]; then
  # first run (root): create key
  vault write -f transit/keys/connector-db exportable=false
fi

# kv v2 at path connector (idempotent)
if ! vault secrets list | grep -q '^connector/'; then
  vault secrets enable -version=2 -path=connector kv
fi

# jwt auth (idempotent)
# (see https://developer.hashicorp.com/vault/docs/auth/jwt#configuration)
: "${KEYCLOAK_REALM_URL:?KEYCLOAK_REALM_URL is required}"
: "${KEYCLOAK_AUDIENCE:?KEYCLOAK_AUDIENCE is required}"
if ! vault auth list | grep -q '^jwt/'; then
  vault auth enable jwt
fi
# configure jwt auth
vault write auth/jwt/config \
  oidc_discovery_url="${KEYCLOAK_REALM_URL}" \
  oidc_client_id="" \
  oidc_client_secret="" \
  default_role="default"

vault write auth/jwt/role/default \
  role_type="jwt" \
  bound_issuer="${KEYCLOAK_REALM_URL}" \
  bound_audiences="${KEYCLOAK_AUDIENCE}" \
  user_claim="sub" \
  token_policies="connector" \
  token_ttl="15m" \
  token_max_ttl="1h"

# TODO: NEEDS PROPER SETUP AND TESTING
# aws auth (idempotent)
if [ "${VAULT_DEV_MODE}" = "false" ]; then
  : "${AWS_REGION:?AWS_REGION is required}"
  : "${AWS_INSTANCE_ROLE_ARN:?AWS_INSTANCE_ROLE_ARN is required}"
  # (see https://developer.hashicorp.com/vault/api-docs/auth/aws#configure-client)
  if ! vault auth list | grep -q '^aws/'; then
    vault auth enable aws
  fi
  # configure aws auth
  vault write auth/aws/config/client sts_region="${AWS_REGION}" \
    sts_endpoint="https://sts.${AWS_REGION}.amazonaws.com"

  # TODO: investigate resolve_aws_unique_ids 
  vault write auth/aws/role/coordinator-ec2 \
    auth_type=iam \
    bound_iam_principal_arn="${AWS_INSTANCE_ROLE_ARN}" \
    resolve_aws_unique_ids=false \
    token_policies="coordinator-ec2" \
    token_ttl="15m" \
    token_max_ttl="1h" \
    token_renewable="false"
fi

# revoke token if prod and set initDone
if [ "${VAULT_DEV_MODE}" = "false" ] && [ ! -f "${INIT_DONE}" ]; then
  vault token revoke -self
  # remove root token to be safe
  jq 'del(.root_token)' "${INIT_JSON}" > "${INIT_JSON}.tmp" && mv "${INIT_JSON}.tmp" "${INIT_JSON}"
  touch "${INIT_DONE}"
  echo "INFO! bootstrap completed and root token revoked"
fi

echo "Done! setting up Vault"
echo "#############################################################################"  