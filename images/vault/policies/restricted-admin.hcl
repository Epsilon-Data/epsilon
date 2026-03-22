# ---- UI / health ----
path "sys/health"        { capabilities = ["read"] }
path "sys/seal-status"   { capabilities = ["read"] }

# ---- Read-only visibility ---- 
path "sys/auth"        { capabilities = ["read", "list"] }
path "sys/mounts"      { capabilities = ["read", "list"] }
path "sys/audit"       { capabilities = ["read", "list"] }
path "sys/policies/acl"    { capabilities = ["read", "list"] }
path "sys/policies/acl/*"  { capabilities = ["read", "list"] }

#  ---- Userpass user admin ONLY  ---- 
path "auth/userpass/users/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# ---- Token self-inspection ----
path "auth/token/lookup-self" { capabilities = ["read"] }