# ---- UI / health ----
path "sys/health"        { capabilities = ["read"] }
path "sys/seal-status"   { capabilities = ["read"] }

# ---- Auth backends + auth config (needed for userpass/jwt/aws management) ----
path "sys/auth"          { capabilities = ["read"] }
path "sys/auth/*"        { capabilities = ["create","read","update","delete","list","sudo"] }
path "auth/*"            { capabilities = ["create","read","update","delete","list","sudo"] }

# ---- Secrets engines (mounts) administration ----
path "sys/mounts"        { capabilities = ["read"] }
path "sys/mounts/*"      { capabilities = ["create","read","update","delete","list","sudo"] }

# ---- Audit devices ----
path "sys/audit"         { capabilities = ["read"] }
path "sys/audit/*"       { capabilities = ["create","read","update","delete","list","sudo"] }

# ---- ACL policies administration ----
path "sys/policies/acl"
{
  capabilities = ["list"]
}

path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# ---- Token self-inspection ----
path "auth/token/lookup-self" { capabilities = ["read"] }

# ---- Explicitly: no access to your user/project secret data or transit decrypt ----
# (Policy is deny-by-default)
# connector/data/*
# connector/metadata/*
# transit/decrypt/*
# transit/export/*
# transit/keys/*
